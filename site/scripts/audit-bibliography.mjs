// Read-only comparison of the website citations, CV bibliography and Crossref.
// Run: node site/scripts/audit-bibliography.mjs [--crossref]
import {readFile, readdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
function parseBib(text) {
  const entries=[];
  const start=/@(\w+)\s*\{\s*([^,]+),/g;
  let match;
  while ((match=start.exec(text))) {
    const entry={type:match[1].toLowerCase(),key:match[2].trim(),fields:{}};
    let i=start.lastIndex;
    while (i<text.length) {
      while (/[\s,]/.test(text[i]||'')) i++;
      if (text[i]==='}') {i++; break;}
      const field=/^([\w-]+)\s*=\s*/.exec(text.slice(i));
      if (!field) throw new Error(`Cannot parse ${entry.key} near ${text.slice(i,i+30)}`);
      i+=field[0].length;
      let value='';
      if (text[i]==='{') {
        let depth=1; i++;
        while (i<text.length && depth) {
          if (text[i]==='\\') {value+=text.slice(i,i+2);i+=2;continue;}
          if (text[i]==='{') depth++;
          if (text[i]==='}') depth--;
          if (depth) value+=text[i];
          i++;
        }
        if (depth) throw new Error(`Unclosed field in ${entry.key}`);
      } else if (text[i]==='"') {
        i++; while (i<text.length && text[i]!=='"') {
          if (text[i]==='\\') {value+=text.slice(i,i+2);i+=2;} else value+=text[i++];
        } i++;
      } else { while (i<text.length && !/[,}\r\n]/.test(text[i])) value+=text[i++]; }
      entry.fields[field[1].toLowerCase()]=value.trim();
    }
    entries.push(entry); start.lastIndex=i;
  }
  return entries;
}
const normalize=value=>String(value??'').normalize('NFKD').replace(/\\(?:["'`^~=.uvHckbdtr])\s*/g,'').replace(/<[^>]*>/g,'').replace(/[^\p{L}\p{N}]/gu,'').toLowerCase();
const cv=parseBib(await readFile(path.resolve(root,'../LaTeX/bibliography.bib'),'utf8'));
const entries=[];
for (const dir of (await readdir(path.join(root,'site/content/publications'),{withFileTypes:true})).filter(e=>e.isDirectory()).map(e=>e.name).sort()) {
  try {
    const file=`site/content/publications/${dir}/cite.bib`;
    const parsed=parseBib(await readFile(path.join(root,file),'utf8'));
    if(parsed.length!==1) throw new Error(`${file}: expected one citation`);
    entries.push({...parsed[0],file});
  } catch(error) {if(error.code!=='ENOENT') throw error;}
}
const report={checkedAt:new Date().toISOString(),websiteCount:entries.length,cvCount:cv.length,results:[]};
for(const entry of entries) {
  const f=entry.fields;
  const doi=f.doi?.replace(/[{}]/g,'').trim();
  const result={file:entry.file,key:entry.key,title:f.title,doi:f.doi||null,cvDifferences:[],crossrefDifferences:[]};
  const candidate=cv.find(e=>f.doi && normalize(e.fields.doi)===normalize(f.doi)) || cv.find(e=>normalize(e.fields.title)===normalize(f.title));
  if(!candidate) result.cvMatch='missing';
  else {
    result.cvMatch=candidate.key;
    for(const field of ['title','author','year','journal','booktitle','volume','number','pages','articleno','doi','isbn','issn','publisher']) {
      if(normalize(f[field])!==normalize(candidate.fields[field])) result.cvDifferences.push({field,website:f[field]??null,cv:candidate.fields[field]??null});
    }
  }
  if(process.argv.includes('--crossref') && doi && !doi.startsWith('10.48550/')) {
    result.source=`https://api.crossref.org/works/${encodeURIComponent(doi)}`;
    try {
      const response=await fetch(result.source,{headers:{'User-Agent':'BibliographyAudit/1.0 (public metadata review)'},signal:AbortSignal.timeout(25000)});
      if(!response.ok) throw new Error(`HTTP ${response.status}`);
      const m=(await response.json()).message;
      const remote={title:[m.title?.[0],m.subtitle?.[0]].filter(Boolean).join(': '),author:m.author?.map(a=>`${a.family}, ${a.given||''}`).join(' and '),volume:m.volume,number:m.issue,pages:m.page,articleno:m['article-number']};
      result.remote={...remote,type:m.type,container:m['container-title']?.[0],publisher:m.publisher,dates:Object.fromEntries(['published','published-print','published-online','issued'].filter(k=>m[k]).map(k=>[k,m[k]['date-parts']])),ISBN:m.ISBN,ISSN:m.ISSN};
      for(const [field,value] of Object.entries(remote)) {
        if(value && normalize(value)!==normalize(f[field])) result.crossrefDifferences.push({field,website:f[field]??null,crossref:value});
      }
      const years=Object.values(result.remote.dates).flat().map(d=>String(d[0]));
      if(years.length && !years.includes(f.year)) result.crossrefDifferences.push({field:'year',website:f.year,crossref:years});
      const months=Object.values(result.remote.dates).flat().filter(d=>String(d[0])===f.year && d[1]).map(d=>String(d[1]));
      const monthNumber=/^\d+$/.test(f.month||'')?Number(f.month):['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'].indexOf(f.month?.toLowerCase())+1;
      if(f.month && monthNumber && months.length && !months.includes(String(monthNumber))) result.crossrefDifferences.push({field:'month',website:f.month,crossref:months});
      for(const identifier of ['isbn','issn']) {
        const values=m[identifier.toUpperCase()];
        if(f[identifier] && values?.length && !values.some(v=>normalize(v)===normalize(f[identifier]))) result.crossrefDifferences.push({field:identifier,website:f[identifier],crossref:values});
      }
      result.crossrefStatus='retrieved';
    }catch(error){result.crossrefStatus=`unavailable: ${error.message}`;}
  } else result.crossrefStatus=f.doi?.startsWith('10.48550/')?'arXiv DOI: separate verification required':f.doi?'not requested':'no DOI: separate verification required';
  report.results.push(result);
}
console.log(JSON.stringify(report,null,2));
