import test from "node:test";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
const source = await readFile(new URL("../assets/js/citation-explorer.js", import.meta.url), "utf8");
const {cumulativeSeries, plotBounds, tooltipPosition, legendOrder, citationTicks} = await import("data:text/javascript;base64," + Buffer.from(source).toString("base64"));

test('citation ticks use round values and cover the largest count', () => {
  assert.deepEqual(citationTicks(99), [0,25,50,75,100]);
  assert.deepEqual(citationTicks(0), [0]);
  assert.deepEqual(citationTicks(3), [0,1,2,3]);
  assert.ok(citationTicks(730).at(-1) >= 730);
});

const data = {totals:[{name:"Scholar",url:"https://scholar.google.com",points:[
  {date:"2025-01-01",kind:"cv_revision",citations:10},
  {date:"2026-01-01",kind:"verified",citations:9}
]}],papers:[{id:"a",title:"A",url:"https://scholar.google.com",snapshots:[
  {date:"2026-09-25",citations:5},{date:"2026-09-30",citations:4}
],annual:{checked_on:"2026-09-30",total:5,years:[{year:2024,citations:1},{year:2026,citations:3}]}}]};

test("cumulative series sums reported counts without inventing years or matching the profile total", () => {
  const [series] = cumulativeSeries(data);
  assert.deepEqual(series.points.map(p=>[p.x,p.y,p.raw]),[[2024,1,1],[2026,4,3]]);
  assert.equal(series.annual.total,5);
});
test("missing annual data remains unavailable rather than synthesized from snapshots", () => {
  const series = cumulativeSeries({papers:[{title:"Missing",snapshots:[{citations:5}],annual:null}]});
  assert.deepEqual(series[0].points,[]);
  assert.equal(plotBounds(series),null);
  assert.equal(plotBounds([]),null);
});
test("cumulative sums sort years without changing the source data", () => {
  const years = [{year:2026,citations:3},{year:2024,citations:2}];
  const [series] = cumulativeSeries({papers:[{title:'A',annual:{years}}]});
  assert.deepEqual(series.points.map(p=>p.y),[2,5]);
  assert.equal(years[0].year,2026);
});
test("single point and zero count charts retain a finite scale", () => {
  const bounds = plotBounds([{points:[{x:2026,y:0}]}]);
  assert.ok(bounds.maxX > bounds.minX && bounds.maxY > bounds.minY);
});
test("tooltip stays beside its point and flips at the right edge", () => {
  const box = {width:200,height:80};
  const right = tooltipPosition({left:100,right:108,top:200,height:8},box,1000,700);
  assert.equal(right.left,116);
  assert.equal(right.top,164);
  assert.equal(right.side,'right');
  const left = tooltipPosition({left:950,right:958,top:200,height:8},box,1000,700);
  assert.equal(left.left,742);
  assert.equal(left.side,'left');
  const edge = tooltipPosition({left:350,right:358,top:2,height:8},box,375,700);
  assert.ok(edge.left >= 8 && edge.left + box.width <= 367 && edge.top >= 8);
});
test("legend puts cited publications first without changing their chart color indices", () => {
  const series = [{name:'A missing',points:[]},{name:'Z cited',points:[{y:3}]},{name:'B zero',points:[{y:0}]},{name:'C cited',points:[{y:1}]}];
  assert.deepEqual(legendOrder(series).map(entry=>entry.index),[3,1,0,2]);
  assert.deepEqual(legendOrder(series,'ascending').map(entry=>entry.index),[3,1,0,2]);
  assert.deepEqual(legendOrder(series,'descending').map(entry=>entry.index),[1,3,0,2]);
  assert.equal(series[0].name,'A missing');
});
