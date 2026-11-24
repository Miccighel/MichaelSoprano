import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {JSDOM} from 'jsdom';

const source = name => readFile(new URL(`../assets/js/${name}`, import.meta.url), 'utf8');
const tick = () => new Promise(resolve => setImmediate(resolve));
test('both theme palettes keep text and control boundaries distinguishable', async () => {
  const css=await readFile(new URL('../assets/css/design-system.css',import.meta.url),'utf8');
  const luminance=hex => {
    const rgb=hex.match(/\w\w/g).map(x=>parseInt(x,16)/255).map(x=>x<=.04045 ? x/12.92 : ((x+.055)/1.055)**2.4);
    return rgb[0]*.2126+rgb[1]*.7152+rgb[2]*.0722;
  };
  const ratio=(a,b)=>{ const x=luminance(a),y=luminance(b); return (Math.max(x,y)+.05)/(Math.min(x,y)+.05); };
  for (const selector of [':root','.dark']) {
    const block=css.slice(css.indexOf(selector+' {')).split('}')[0];
    const colors=Object.fromEntries([...block.matchAll(/--site-([\w-]+): #(\w{6});/g)].map(m=>[m[1],m[2]]));
    for (const foreground of ['text','muted','primary','primary-hover']) {
      for (const background of ['background','background-alt','surface','primary-soft']) {
        assert.ok(ratio(colors[foreground],colors[background])>=4.5,`${selector}: ${foreground} on ${background}`);
      }
    }
    assert.ok(ratio(colors['control-border'],colors.background)>=3,`${selector}: control outline`);
  }
  assert.doesNotMatch(css,/font-size: \.(?:[0-6]\d*)rem;/);
});
async function fixture(html) {
  const dom = new JSDOM(html, {url:'https://michaelsoprano.com/', runScripts:'outside-only', pretendToBeVisual:true});
  await tick(); // Let the initial DOMContentLoaded finish before registering scripts.
  dom.window.HTMLElement.prototype.scrollIntoView = function() { this.dataset.scrolled = 'true'; };
  dom.window.Element.prototype.getBoundingClientRect = () => ({x:0,y:0,left:0,right:20,top:0,bottom:20,width:20,height:20});
  return dom;
}
function key(window, target, name, options = {}) {
  target.dispatchEvent(new window.KeyboardEvent('keydown', {key:name,bubbles:true,cancelable:true,...options}));
}

test('citation dialog copies BibTeX, traps focus and restores its trigger on Escape', async t => {
  const dom = await fixture(`<button class="legacy-cite" data-cite-title="Evidence &amp; evaluation" data-cite-url="/cite.bib">Cite</button><div id="legacy-cite-modal" hidden><p id="legacy-cite-paper"></p><button class="legacy-cite-close">Close</button><div tabindex="0"><code id="legacy-cite-code"></code></div><button id="legacy-cite-copy">Copy BibTeX</button><a id="legacy-cite-download">Download .bib</a><span id="legacy-cite-status" role="status"></span></div>`);
  t.after(()=>dom.window.close());
  const {window:w}=dom, d=w.document;
  const citation='@article{example,\n  title = {Text <script>not HTML</script>},\n  year = {2026}\n}';
  w.fetch=async()=>({ok:true,text:async()=>citation});
  w.URL.createObjectURL=()=> 'blob:citation';
  w.URL.revokeObjectURL=()=>{};
  let copied;
  Object.defineProperty(w.navigator,'clipboard',{value:{writeText:async text=>{copied=text;}}});
  w.eval(await source('site-citations.js'));
  const trigger=d.querySelector('.legacy-cite'), modal=d.querySelector('#legacy-cite-modal');
  trigger.focus(); trigger.click(); await tick();
  assert.equal(modal.hidden,false);
  assert.equal(d.querySelector('#legacy-cite-paper').textContent,'Evidence & evaluation');
  assert.equal(d.activeElement.id,'legacy-cite-copy');
  assert.equal(d.querySelector('#legacy-cite-code').textContent,citation);
  assert.equal(d.querySelector('#legacy-cite-code script'),null);
  assert.equal(d.querySelector('.bibtex-type').textContent,'@article');
  assert.equal(d.querySelector('.bibtex-field').textContent,'title');
  d.activeElement.click(); await tick();
  assert.equal(copied,citation);
  assert.match(d.querySelector('#legacy-cite-status').textContent,/copied/);
  const download=d.querySelector('#legacy-cite-download');
  download.focus(); key(w,download,'Tab');
  assert.equal(d.activeElement.className,'legacy-cite-close');
  key(w,d.activeElement,'Tab',{shiftKey:true});
  assert.equal(d.activeElement,download);
  key(w,download,'Escape');
  assert.equal(modal.hidden,true);
  assert.equal(d.activeElement,trigger);
  assert.equal(d.body.style.overflow,'');
});
async function eventually(assertion) {
  for (let i=0;i<100;i++) {
    try { assertion(); return; } catch (error) {
      if (i === 99) throw error;
      await new Promise(resolve => setTimeout(resolve,10));
    }
  }
}

test('mobile navigation closes after choosing a section; dropdown supports keyboard', async t => {
  const dom = await fixture(`<header class="page-header"></header><button id="nav-toggle" aria-expanded="false">Navigation menu</button><nav id="nav-menu"><a href="/#teaching">Teaching</a></nav><section id="teaching"></section><div class="nav-dropdown"><a class="nav-link" role="button" href="#" aria-expanded="false">More</a></div>`);
  t.after(() => dom.window.close());
  const {window:w} = dom, d=w.document;
  w.eval(await source('homepage-nav.js'));
  w.eval(await source('hb-nav.js'));
  w.dispatchEvent(new w.Event('DOMContentLoaded'));
  const menuButton=d.querySelector('#nav-toggle');
  menuButton.click();
  assert.equal(menuButton.getAttribute('aria-expanded'),'true');
  d.querySelector('#nav-menu a').focus();
  key(w,d.activeElement,'Escape');
  assert.equal(d.activeElement,menuButton);
  assert.equal(menuButton.getAttribute('aria-expanded'),'false');
  menuButton.click();
  d.querySelector('#nav-menu a').click();
  assert.equal(menuButton.getAttribute('aria-expanded'),'false');
  const toggle=d.querySelector('.nav-link');
  key(w,toggle,'Enter'); assert.equal(toggle.getAttribute('aria-expanded'),'true');
  key(w,toggle,'Escape'); assert.equal(toggle.getAttribute('aria-expanded'),'false');
});

test('homepage navigation follows reading position and selects Contact at the end of the page', async t => {
  const dom=await fixture('<nav id="nav-menu"><a href="/#tags">Topics</a><a href="/#contact">Contact</a></nav><section id="tags"></section><section id="contact"></section>');
  t.after(()=>dom.window.close());
  const {window:w}=dom,d=w.document,root=d.documentElement;
  Object.defineProperties(root,{clientHeight:{value:1200},scrollHeight:{value:3200}});
  d.querySelector('#tags').getBoundingClientRect=()=>({top:1500-w.scrollY});
  d.querySelector('#contact').getBoundingClientRect=()=>({top:2350-w.scrollY});
  w.scrollY=1800;
  w.eval(await source('homepage-nav.js'));
  const selected=()=>[...d.querySelectorAll('#nav-menu a.active[aria-current="location"]')].map(a=>a.hash);
  await eventually(()=>assert.deepEqual(selected(),['#tags']));
  w.scrollY=2000; w.dispatchEvent(new w.Event('scroll'));
  await eventually(()=>assert.deepEqual(selected(),['#contact']));
  w.scrollY=1800; w.dispatchEvent(new w.Event('scroll'));
  await eventually(()=>assert.deepEqual(selected(),['#tags']));
});

test('publication filters combine title, author, type and year and expose empty state', async t => {
  const dom = await fixture(`<input id="publication-search"><select id="publication-type-filter"><option value=""></option><option value="article-journal">Journal</option></select><select id="publication-year-filter"><option value=""></option><option value="2025">2025</option></select><div id="publication-archive-list"><section data-publication-year-group><article data-title="alpha" data-authors="soprano" data-type="article-journal" data-year="2025"></article></section><section data-publication-year-group><article data-title="beta" data-authors="other" data-type="paper-conference" data-year="2026"></article></section></div><p id="publication-archive-empty" hidden></p>`);
  t.after(() => dom.window.close());
  const {window:w}=dom,d=w.document;
  w.eval(await source('publication-filters.js'));
  const search=d.querySelector('input'); search.value='soprano'; search.dispatchEvent(new w.Event('input'));
  assert.equal(d.querySelectorAll('article:not([hidden])').length,1);
  d.querySelector('#publication-year-filter').value='2025';
  d.querySelector('#publication-year-filter').dispatchEvent(new w.Event('change'));
  assert.equal(d.querySelectorAll('[data-publication-year-group]:not([hidden])').length,1);
  const type=d.querySelector('#publication-type-filter');
  type.value='article-journal'; type.dispatchEvent(new w.Event('change'));
  assert.equal(w.location.search,'?q=soprano&year=2025&type=article-journal');
  const reopened=await fixture(dom.serialize());
  t.after(()=>reopened.window.close());
  reopened.window.history.replaceState(null,'',w.location.pathname+w.location.search);
  reopened.window.eval(await source('publication-filters.js'));
  const rd=reopened.window.document;
  assert.deepEqual([...rd.querySelectorAll('input, select')].map(el=>el.value),['soprano','article-journal','2025']);
  assert.equal(rd.querySelectorAll('article:not([hidden])').length,1);
  type.value=''; type.dispatchEvent(new w.Event('change'));
  search.value='absent'; search.dispatchEvent(new w.Event('input'));
  assert.equal(d.querySelector('#publication-archive-empty').hidden,false);
  search.value=''; d.querySelector('#publication-year-filter').value=''; search.dispatchEvent(new w.Event('input'));
  assert.equal(d.querySelectorAll('article:not([hidden])').length,2);
});

test('publication reset clears filters, legacy hash and restores all results', async t => {
  const dom = await fixture(`<input id="publication-search"><select id="publication-type-filter"><option value=""></option><option value="article-journal">Journal</option></select><select id="publication-year-filter"><option value=""></option><option value="2025">2025</option></select><button id="publication-filter-reset" hidden>Clear filters</button><p id="publication-result-count" role="status"></p><div id="publication-archive-list"><section data-publication-year-group><article data-title="alpha" data-authors="soprano" data-type="article-journal" data-year="2025"></article><article data-title="beta" data-authors="other" data-type="paper-conference" data-year="2026"></article></section></div><p id="publication-archive-empty" hidden></p>`);
  t.after(() => dom.window.close());
  const {window:w}=dom,d=w.document;
  w.history.replaceState(null,'','/publication/?q=alpha#2');
  w.eval(await source('publication-filters.js'));
  const reset=d.querySelector('#publication-filter-reset'), count=d.querySelector('#publication-result-count');
  assert.equal(count.textContent,'1 of 2 publications');
  assert.equal(d.querySelector('#publication-search').value,'alpha');
  assert.equal(d.querySelector('#publication-type-filter').value,'article-journal');
  assert.equal(reset.hidden,false);
  const search=d.querySelector('#publication-search');
  search.value='missing'; search.dispatchEvent(new w.Event('input'));
  assert.equal(count.textContent,'0 of 2 publications');
  reset.click();
  assert.equal(count.textContent,'2 publications');
  assert.equal(reset.hidden,true);
  assert.equal(d.querySelector('#publication-archive-empty').hidden,true);
  assert.equal(w.location.hash,'');
  assert.equal(w.location.search,'');
  assert.equal(d.activeElement,search);
});

test('publication search combines venue, year, author and punctuation-insensitive title words', async t => {
  const dom=await fixture('<input id="publication-search"><select id="publication-type-filter"></select><select id="publication-year-filter"></select><div id="publication-archive-list"><article data-title="Fact–Checking" data-authors="José Silva" data-year="2025"><div class="publication-archive-meta">ACM SIGIR</div></article></div><p id="publication-archive-empty" hidden></p>');
  t.after(()=>dom.window.close());
  const {window:w}=dom,d=w.document,input=d.querySelector('input');
  w.eval(await source('publication-filters.js'));
  for(const [q,expected] of [['SIGIR 2025',true],['fact checking',true],['silva fact-checking',true],['Jose SIGIR',true],['SIGIR 2024',false]]){
    input.value=q; input.dispatchEvent(new w.Event('input'));
    assert.equal(!d.querySelector('article').hidden,expected,q);
  }
});

test('publication returns to filtered results only from the same archive', async t => {
  const js=await source('publication-return.js');
  const original='/publication/';
  const cases=[
    ['https://michaelsoprano.com/publication/?q=peer+review&type=paper-conference&year=2025&extra=no', '/publication/?q=peer+review&type=paper-conference&year=2025'],
    ['https://michaelsoprano.com/publication/', original],
    ['https://michaelsoprano.com/tag/peer-review/?q=peer', original],
    ['https://other.example/publication/?q=peer', original],
    [undefined, original],
  ];
  for (const [referrer,expected] of cases) {
    const dom=new JSDOM('<a href="/publication/" data-publication-return><span>All publications</span></a>',{url:'https://michaelsoprano.com/publication/paper/',referrer,runScripts:'outside-only'});
    t.after(()=>dom.window.close());
    const {window:w}=dom;
    w.eval(js);
    const link=w.document.querySelector('a'), url=new URL(link.href);
    assert.equal(url.pathname+url.search,expected,referrer);
    assert.equal(link.textContent,expected===original?'All publications':'Back to results');
  }
});

test('topic filter matches aliases and hides empty letter groups, with a shareable query', async t => {
  const dom=await fixture('<main class="topic-directory"><div class="topic-filter" hidden><input id="topic-query"><button data-topic-clear hidden>Clear</button><p data-topic-status role="status"></p></div><nav class="topic-letters"><a href="#topics-a">A</a><a href="#topics-c">C</a></nav><section class="topic-letter-group" aria-labelledby="topics-a"><h2 id="topics-a">A</h2><ul><li data-topic-aliases="ai"><a class="topic-directory-link"><span>Artificial Intelligence</span><span>3</span></a></li></ul></section><section class="topic-letter-group" aria-labelledby="topics-c"><h2 id="topics-c">C</h2><ul><li data-topic-aliases="cognitive-bias"><a class="topic-directory-link"><span>Cognitive Biases</span><span>2</span></a></li><li><a class="topic-directory-link"><span>Crowd_Frame</span><span>2</span></a></li></ul></section></main>');
  t.after(()=>dom.window.close());
  const {window:w}=dom,d=w.document,input=d.querySelector('#topic-query');
  const names=()=>[...d.querySelectorAll('.topic-letter-group li:not([hidden]) a > span:first-child')].map(a=>a.textContent);
  const letters=()=>[...d.querySelectorAll('.topic-letters a:not([hidden])')].map(a=>a.textContent);
  const set=value=>{input.value=value; input.dispatchEvent(new w.Event('input'));};
  w.history.replaceState(null,'','/tags/?q=AI');
  w.eval(await source('topic-filter.js'));
  assert.equal(d.querySelector('.topic-filter').hidden,false);
  assert.deepEqual(names(),['Artificial Intelligence']);
  assert.deepEqual(letters(),['A']);
  assert.equal(d.querySelector('[data-topic-status]').textContent,'1 of 3 topics');
  set('CROWD frame');
  assert.deepEqual(names(),['Crowd_Frame']);
  assert.deepEqual(letters(),['C']);
  assert.equal(new URL(w.location.href).searchParams.get('q'),'CROWD frame');
  set('cognítive bias');
  assert.deepEqual(names(),['Cognitive Biases']);
  set('not there');
  assert.ok(d.querySelector('.topic-letters').hidden);
  assert.equal(d.querySelector('[data-topic-status]').textContent,'No topics match.');
  d.querySelector('[data-topic-clear]').click();
  assert.deepEqual(letters(),['A','C']);
  assert.equal(names().length,3);
  assert.equal(w.location.search,'');
  assert.equal(d.activeElement,input);
});

test('search opens, shows results, handles navigation and Escape, restores focus', async t => {
  const markup=await readFile(new URL('../layouts/_partials/components/search-modal.html',import.meta.url),'utf8');
  const dom=await fixture('<button data-search-toggle>Search</button>'+markup);
  t.after(() => dom.window.close());
  const {window:w}=dom,d=w.document;
  // Stub only the external Pagefind module; run the actual interaction code.
  w.__loadPagefind=async () => ({init:async()=>{},search:async query=>({results: query === 'missing' ? [] : Array.from({length:16},(_,i)=>({data:async()=>({url:'#'+i,meta:{title:'Paper '+i,kind:'Publication',year:'2026',venue:'Test journal',summary:'Abstract text'},excerpt:'Repeated title'})}))})});
  w.eval((await source('hb-search.js')).replace('import(modal.dataset.pagefindUrl)','window.__loadPagefind()'));
  d.dispatchEvent(new w.Event('DOMContentLoaded'));
  const toggle=d.querySelector('[data-search-toggle]'); toggle.focus(); toggle.click();
  assert.equal(d.querySelector('#site-search').hidden,false);
  const input=d.querySelector('input'); assert.equal(d.activeElement,input);
  input.value='alpha'; input.dispatchEvent(new w.Event('input'));
  await eventually(()=>assert.equal(d.querySelectorAll('#site-search-results a').length,10));
  const more=d.querySelector('[data-search-more]');
  assert.equal(more.textContent,'Show 6 more');
  assert.equal(d.querySelector('[data-search-status]').textContent,'Showing 10 of 16 results.');
  assert.equal(d.querySelector('.site-search-result-venue').textContent,'Test journal');
  assert.equal(d.querySelector('.site-search-result p').textContent,'Abstract text');
  assert.equal(input.getAttribute('aria-expanded'),'true');
  assert.equal(d.querySelector('.site-search-result-meta').textContent,'Publication · 2026');
  assert.equal(d.querySelector('.site-search-result-meta').hidden,false);
  key(w,input,'ArrowDown'); assert.equal(input.getAttribute('aria-activedescendant'),'site-search-result-1');
  more.click();
  await eventually(()=>assert.equal(d.querySelectorAll('#site-search-results a').length,16));
  assert.equal(d.activeElement,input);
  assert.equal(input.getAttribute('aria-activedescendant'),'site-search-result-10');
  assert.ok([...d.querySelectorAll('#site-search-results a')].every(link=>link.tabIndex === -1));
  assert.equal(more.hidden,true);
  input.focus();
  input.value='missing'; input.dispatchEvent(new w.Event('input'));
  await eventually(()=>assert.equal(d.querySelector('[data-search-status]').textContent,'No results found.'));
  const empty=d.querySelector('[data-search-empty]');
  assert.ok(!empty.classList.contains('hidden'));
  assert.doesNotMatch(empty.textContent,/no results found/i);
  assert.equal(empty.querySelector('a').getAttribute('href'),'/tags/');
  assert.equal(input.getAttribute('aria-expanded'),'false');
  key(w,input,'Escape'); assert.equal(d.querySelector('#site-search').hidden,true);
  assert.equal(d.activeElement,toggle);
  key(w,d,'k',{ctrlKey:true}); assert.equal(d.querySelector('#site-search').hidden,false);
});

test('chart has one keyboard entry, arrow navigation, tooltips, selection, sorting and reset', async t => {
  const template=await readFile(new URL('../layouts/_default/citation-history.html',import.meta.url),'utf8');
  const dom=await fixture(template.slice(template.indexOf('<main'),template.lastIndexOf('</main>')+7));
  t.after(()=>dom.window.close());
  const {window:w}=dom,d=w.document;
  w.matchMedia=()=>({matches:true}); w.ResizeObserver=class {observe() {}};
  const chart=d.querySelector('#citation-chart');
  Object.defineProperty(chart,'clientWidth',{value:305});
  Object.defineProperty(d.documentElement,'clientWidth',{value:390});
  Object.defineProperty(d.documentElement,'clientHeight',{value:844});
  w.fetch=async()=>({ok:true,json:async()=>({schema:1,papers:[
    {title:'Alpha',annual:{checked_on:'2026-09-30',total:4,years:[{year:2024,citations:1},{year:2026,citations:3}]}},
    {title:'Beta',annual:{checked_on:'2026-09-30',total:7,years:[{year:2025,citations:7}]}},
    {title:'Missing',annual:null}
  ]})});
  w.eval((await source('citation-explorer.js')).replaceAll('export function','function'));
  await eventually(()=>assert.ok(chart.querySelector('svg')));
  assert.equal(chart.querySelectorAll('[tabindex="0"]').length,0);
  assert.equal(chart.querySelectorAll('circle:not([tabindex="-1"]),polyline:not([tabindex="-1"])').length,0);
  chart.focus(); assert.equal(chart.getAttribute('aria-activedescendant'),'citation-point-0-1');
  const tooltip=d.querySelector('#citation-tooltip'); assert.equal(tooltip.hidden,false);
  key(w,chart,'ArrowLeft'); assert.match(tooltip.textContent,/1 cumulative citations/);
  assert.match(d.querySelector('#citation-announcement').textContent,/Alpha.*1 cumulative citations.*2024/);
  key(w,chart,'ArrowDown'); assert.match(tooltip.textContent,/Beta/);
  assert.match(d.querySelector('#citation-announcement').textContent,/Beta.*7 cumulative citations.*2025/);
  key(w,chart,'Enter'); assert.equal(d.querySelector('#citation-selected-title').textContent,'Beta');
  key(w,chart,'Escape'); assert.equal(tooltip.hidden,true);
  d.querySelector('.citation-view-chart:not([hidden])').click(); assert.equal(chart.dataset.scrolled,'true');
  const sort=d.querySelector('#citation-sort'); sort.value='descending'; sort.dispatchEvent(new w.Event('change'));
  assert.match(d.querySelector('.citation-series-key').textContent,/Beta/);
  const search=d.querySelector('#citation-search'); search.value='alpha'; search.dispatchEvent(new w.Event('input'));
  assert.equal(d.querySelectorAll('.citation-series-key:not([hidden])').length,1);
  d.querySelector('#citation-reset').click(); assert.equal(d.querySelector('#citation-selected-title').hidden,true);
  const point=chart.querySelector('circle'); point.dispatchEvent(new w.Event('pointerenter'));
  assert.equal(tooltip.hidden,false); point.dispatchEvent(new w.Event('pointerleave')); assert.equal(tooltip.hidden,true);
});
