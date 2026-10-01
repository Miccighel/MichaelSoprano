// Cumulative sums of reported annual counts; never adjusted to profile totals.
export function cumulativeSeries(data) {
  return data.papers.map(paper => {
    let cumulative = 0;
    return {
      name: paper.title, url: paper.url, annual: paper.annual,
      points: [...(paper.annual?.years ?? [])].sort((a,b) => a.year - b.year).map(p => {
        cumulative += p.citations;
        return {...p, x:p.year, y:cumulative, raw:p.citations};
      })
    };
  });
}

export function plotBounds(series) {
  const points = series.flatMap(s => s.points);
  if (!points.length) return null;
  let minX = Math.min(...points.map(p => p.x)), maxX = Math.max(...points.map(p => p.x));
  if (minX === maxX) { minX -= .5; maxX += .5; }
  const minY = Math.min(0, ...points.map(p => p.y));
  const maximum = Math.max(0, ...points.map(p => p.y));
  return {minX, maxX, minY, maxY: maximum === minY ? minY + 1 : maximum + (maximum - minY) * .12};
}

export function citationTicks(maximum) {
  const rough = Math.max(1, maximum) / 4;
  const magnitude = 10 ** Math.floor(Math.log10(rough));
  const step = [1, 2, 2.5, 5, 10].map(n => n * magnitude).find(n => n >= rough);
  const integerStep = Math.max(1, step);
  return Array.from({length: Math.ceil(maximum / integerStep) + 1}, (_, i) => i * integerStep);
}

export function keyboardPoint(series, current, key, selected = null) {
  const available = series.map((s, index) => index).filter(index => series[index].points.length);
  if (!available.length) return null;
  let index = current?.series ?? (available.includes(selected) ? selected : available[0]);
  let point = Math.min(current?.point ?? series[index].points.length - 1, series[index].points.length - 1);
  if (key === 'ArrowUp' || key === 'ArrowDown') {
    const year = series[index].points[point].x;
    index = available[Math.max(0, Math.min(available.length - 1, available.indexOf(index) + (key === 'ArrowDown' ? 1 : -1)))];
    point = series[index].points.reduce((nearest, p, i, points) => Math.abs(p.x-year) < Math.abs(points[nearest].x-year) ? i : nearest, 0);
  } else if (key === 'ArrowLeft') point = Math.max(0, point - 1);
  else if (key === 'ArrowRight') point = Math.min(series[index].points.length - 1, point + 1);
  else if (key === 'Home') point = 0;
  else if (key === 'End') point = series[index].points.length - 1;
  return {series:index, point};
}

export function legendOrder(series, order = 'alphabetical') {
  return series.map((s,index) => ({s,index})).sort((a,b) => {
    const hasCitations = s => (s.points.at(-1)?.y ?? 0) > 0;
    const group = Number(hasCitations(b.s)) - Number(hasCitations(a.s));
    if (group) return group;
    const delta = (a.s.points.at(-1)?.y ?? 0) - (b.s.points.at(-1)?.y ?? 0);
    const numerical = order === 'ascending' ? delta : order === 'descending' ? -delta : 0;
    return numerical || a.s.name.localeCompare(b.s.name, 'en');
  });
}

const NS = "http://www.w3.org/2000/svg";
export function tooltipPosition(anchor, box, viewportWidth, viewportHeight) {
  const gap = 8, margin = 8;
  const right = anchor.right + gap;
  const side = right + box.width <= viewportWidth - margin ? 'right' : 'left';
  const left = Math.max(margin, Math.min(viewportWidth - box.width - margin,
    side === 'right' ? right : anchor.left - box.width - gap));
  const center = anchor.top + anchor.height / 2;
  const top = Math.max(margin, Math.min(viewportHeight - box.height - margin, center - box.height / 2));
  return {left, top, side, arrowTop:Math.max(10, Math.min(box.height - 10, center - top))};
}
const dateLabel = day => new Intl.DateTimeFormat("en", {day:"numeric", month:"short", year:"numeric", timeZone:"UTC"}).format(new Date(day));
function svgElement(tag, attrs = {}, text) {
  const el = document.createElementNS(NS, tag);
  for (const [key, value] of Object.entries(attrs)) el.setAttribute(key, String(value));
  if (text !== undefined) el.textContent = text;
  return el;
}

async function initialize(root) {
  const context = root.querySelector("#citation-context");
  let data;
  try {
    const response = await fetch(root.dataset.seriesUrl);
    if (!response.ok) throw new Error("Data unavailable");
    data = await response.json();
    if (data.schema !== 1 || !data.papers?.length) throw new Error("Invalid data");
  } catch {
    context.textContent = "The interactive chart could not be loaded. Please reload the page.";
    context.hidden = false;
    return;
  }
  const chart = root.querySelector("#citation-chart");
  const legend = root.querySelector("#citation-legend");
  const tooltip = root.querySelector("#citation-tooltip");
  const search = root.querySelector("#citation-search");
  const sort = root.querySelector("#citation-sort");
  const reset = root.querySelector("#citation-reset");
  const selectedTitle = root.querySelector('#citation-selected-title');
  let selected = null;
  let keyboard = null;
  const hideTooltip = () => { tooltip.hidden = true; };
  function showTooltip(point, s, p) {
    tooltip.replaceChildren();
    const name = document.createElement('strong'); name.textContent = s.name;
    const value = document.createElement('span'); value.className = 'citation-tooltip-value';
    value.textContent = p.y + ' cumulative citations';
    const detail = document.createElement('span');
    detail.textContent = p.year + ' · ' + p.raw + ' received that year' + (p.year === Number(s.annual.checked_on.slice(0,4)) ? ' · Partial year' : '');
    tooltip.append(name, value, detail); tooltip.hidden = false;
    if (document.activeElement === chart) {
      root.querySelector('#citation-announcement').textContent = s.name + '. ' + value.textContent + '. ' + detail.textContent;
    }
    const anchor = point.getBoundingClientRect(), box = tooltip.getBoundingClientRect();
    const viewportWidth = document.documentElement.clientWidth;
    const viewportHeight = document.documentElement.clientHeight;
    const position = tooltipPosition(anchor, box, viewportWidth, viewportHeight);
    tooltip.style.left = position.left + 'px';
    tooltip.style.top = position.top + 'px';
    tooltip.dataset.side = position.side;
    tooltip.style.setProperty('--tooltip-arrow-top', position.arrowTop + 'px');
  }
  window.addEventListener('scroll', hideTooltip, {passive:true});
  chart.addEventListener('scroll', hideTooltip, {passive:true});
  window.addEventListener('resize', hideTooltip);
  root.addEventListener('keydown', event => { if (event.key === 'Escape') hideTooltip(); });
  function render() {
    const series = cumulativeSeries(data);
    const color = index => {
      const hue = (index * 137.508 + 235) % 360;
      return `light-dark(hsl(${hue} 55% 36%), hsl(${hue} 55% 72%))`;
    };
    const highlight = index => {
      const active = index ?? selected;
      chart.querySelectorAll('[data-series]').forEach(el => {
        el.style.opacity = active === null || el.dataset.series === String(active) ? '1' : '.12';
        if (el.classList.contains('citation-line')) el.style.strokeWidth = active !== null && el.dataset.series === String(active) ? '4' : '2.5';
      });
    };
    const updateSelection = () => {
      selectedTitle.hidden = selected === null;
      selectedTitle.textContent = selected === null ? '' : series[selected].name;
      legend.querySelectorAll('.citation-view-chart').forEach(button => { button.hidden = Number(button.dataset.seriesIndex) !== selected; });
    };
    const selectSeries = index => {
      selected = selected === index ? null : index;
      reset.disabled = selected === null;
      legend.querySelectorAll('button[aria-pressed]').forEach(button => button.setAttribute('aria-pressed', String(Number(button.parentElement.dataset.seriesIndex) === selected)));
      highlight(null); updateSelection();
    };
    const inspectKeyboardPoint = key => {
      keyboard = keyboardPoint(series, keyboard, key, selected);
      if (!keyboard) return;
      const point = chart.querySelector(`[data-series="${keyboard.series}"][data-point="${keyboard.point}"]`);
      if (!point) return;
      chart.setAttribute('aria-activedescendant', point.id);
      highlight(keyboard.series);
      showTooltip(point, series[keyboard.series], series[keyboard.series].points[keyboard.point]);
    };
    chart.addEventListener('focus', () => { keyboard = null; inspectKeyboardPoint(); });
    chart.addEventListener('blur', () => { hideTooltip(); highlight(null); chart.removeAttribute('aria-activedescendant'); });
    chart.addEventListener('keydown', event => {
      if (['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','Home','End'].includes(event.key)) {
        event.preventDefault(); inspectKeyboardPoint(event.key);
      } else if (event.key === 'Enter' && keyboard) {
        event.preventDefault(); selectSeries(keyboard.series);
      } else if (event.key === 'Escape') { hideTooltip(); highlight(null); }
    });
    const filterLegend = () => {
      const query = search.value.trim().toLocaleLowerCase();
      let count = 0;
      for (const item of legend.children) {
        item.hidden = !item.dataset.title.includes(query);
        if (!item.hidden) count++;
      }
      root.querySelector('#citation-search-status').textContent = count ? count + ' of ' + series.length + ' publications · Select a title to highlight its line.' : 'No matching publications.';
    };
    search.addEventListener('input', filterLegend);
    reset.addEventListener('click', () => {
      selected = null; reset.disabled = true; hideTooltip(); highlight(null);
      legend.querySelectorAll('button[aria-pressed]').forEach(button => button.setAttribute('aria-pressed','false'));
      updateSelection();
    });
    const bounds = plotBounds(series);
    if (bounds) {
      const years = series.flatMap(s => s.points.map(p => p.x));
      bounds.minX = Math.min(...years) - .5;
      bounds.maxX = Math.max(...years) + .5;
    }
    chart.replaceChildren(); legend.replaceChildren();
    legendOrder(series).forEach(({s, index}) => {
      const item = document.createElement("div");
      item.className = "citation-series-key";
      item.dataset.seriesIndex = index;
      item.dataset.title = s.name.toLocaleLowerCase();
      const link = document.createElement("button"); link.type = "button";
      link.setAttribute('aria-pressed','false'); link.disabled = !s.points.length;
      const swatch = document.createElement('span'); swatch.className = 'citation-swatch'; swatch.style.background = color(index); swatch.setAttribute('aria-hidden','true');
      const title = document.createElement('span'); title.textContent = s.name; title.className = 'citation-publication-title';
      const count = document.createElement('span'); count.className = 'citation-publication-count';
      count.textContent = s.points.length ? String(s.points.at(-1).y) : 'No data';
      count.setAttribute('aria-label', s.points.length ? s.points.at(-1).y + ' cumulative citations' : 'Annual data unavailable');
      link.append(swatch,title,count);
      for (const event of ['pointerenter','focus']) link.addEventListener(event, () => { hideTooltip(); highlight(index); });
      link.addEventListener('click', () => {
        selectSeries(index);
      });
      for (const event of ['pointerleave','blur']) link.addEventListener(event, () => highlight(null));
      item.append(link);
      const viewChart = document.createElement('button');
      viewChart.type = 'button'; viewChart.className = 'citation-view-chart'; viewChart.hidden = true;
      viewChart.dataset.seriesIndex = index; viewChart.textContent = 'View in chart ↑';
      viewChart.addEventListener('click', () => { chart.scrollIntoView({behavior:window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth',block:'center'}); chart.focus({preventScroll:true}); });
      item.append(viewChart);
      const note = document.createElement("span");
      const sum = s.points.reduce((total, p) => total + p.raw, 0);
      note.textContent = s.points.length
        ? "Checked " + dateLabel(s.annual.checked_on) + " · Cumulative sum: " + sum + (s.annual.total !== null ? " · Reported total: " + s.annual.total : "")
        : "No annual series reported";
      link.title = note.textContent;
      legend.append(item);
    });
    const orderLegend = () => {
      const items = new Map([...legend.children].map(item => [Number(item.dataset.seriesIndex), item]));
      for (const {index} of legendOrder(series, sort.value)) legend.append(items.get(index));
      filterLegend();
    };
    sort.addEventListener('change', orderLegend);
    orderLegend();
    filterLegend();
    if (!bounds) { context.textContent = "No annual citation data available."; context.hidden = false; return; }
    function drawChart() {
    hideTooltip(); chart.replaceChildren();
    const width = Math.max(220, chart.clientWidth), height = width < 600 ? 300 : 340, left = 38, right = 22, top = 24, bottom = 40;
    const yTicks = citationTicks(Math.max(...series.flatMap(s => s.points.map(p => p.y))));
    bounds.maxY = yTicks.at(-1) || 1;
    const x = n => left + (n - bounds.minX) / (bounds.maxX - bounds.minX) * (width - left - right);
    const y = n => height - bottom - (n - bounds.minY) / (bounds.maxY - bounds.minY) * (height - top - bottom);
    const svg = svgElement("svg", {viewBox:"0 0 " + width + " " + height, role:"group", "aria-label":"Cumulative citations by year"});
    svg.append(svgElement("title", {}, "Cumulative citations by year"));
    for (const value of yTicks) {
      svg.append(svgElement("line", {x1:left,x2:width-right,y1:y(value),y2:y(value),class:"citation-grid-line"}));
      svg.append(svgElement("text", {x:left-10,y:y(value)+4,"text-anchor":"end",class:"citation-axis"}, String(Math.round(value))));
    }
    const distinct = [...new Set(series.flatMap(s => s.points.map(p => p.x)))].sort((a,b) => a-b);
    const yearStride = Math.max(1, Math.ceil(distinct.length / Math.max(2, Math.floor((width-left-right) / 60))));
    for (const [i, value] of distinct.entries()) if (i === distinct.length-1 || (i % yearStride === 0 && (i === 0 || distinct.length-1-i >= yearStride))) svg.append(svgElement("text", {
      x:x(value),y:height-16,"text-anchor":"middle",class:"citation-axis"
    }, String(value)));
    series.forEach((s, index) => {
      if (s.points.length > 1) {
        const line = svgElement("polyline", {
          points:s.points.map(p => x(p.x) + "," + y(p.y)).join(" "),class:"citation-line", 'data-series':index,
          tabindex:-1, role:'img', 'aria-label':s.name
        });
        line.style.stroke = color(index);
        line.append(svgElement('title', {}, s.name));
        for (const event of ['pointerenter','focus']) line.addEventListener(event, () => highlight(index));
        for (const event of ['pointerleave','blur']) line.addEventListener(event, () => highlight(null));
        svg.append(line);
      }
      s.points.forEach((p, pointIndex) => {
        const label = s.name + " · " + p.year + " · " + p.y + " cumulative citations · " + p.raw + " received that year"
          + (p.year === Number(s.annual.checked_on.slice(0,4)) ? " · Partial year" : "");
        let point;
        point = svgElement("circle", {cx:x(p.x),cy:y(p.y),r:3.5});
        point.setAttribute("class", "citation-point");
        point.id = `citation-point-${index}-${pointIndex}`;
        point.dataset.point = pointIndex;
        point.setAttribute('tabindex','-1');
        point.setAttribute("role", "img"); point.setAttribute("aria-label",label);
        point.setAttribute('aria-describedby','citation-tooltip');
        point.dataset.series = index;
        point.style.stroke = color(index); point.style.fill = color(index);
        for (const event of ["pointerenter","focus","click"]) point.addEventListener(event, () => { highlight(index); showTooltip(point,s,p); });
        for (const event of ['pointerleave','blur']) point.addEventListener(event, () => { hideTooltip(); highlight(null); });
        svg.append(point);
      });
    });
    chart.append(svg);
    highlight(null);
    if (document.activeElement === chart) inspectKeyboardPoint();
    }
    drawChart();
    new ResizeObserver(drawChart).observe(chart);
  }
  render();
}

if (typeof document !== "undefined") document.querySelectorAll("[data-citation-explorer]").forEach(initialize);
