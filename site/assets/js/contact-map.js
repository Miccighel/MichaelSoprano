(() => {
  const mapElement = document.getElementById("map");
  if (!mapElement || typeof L === "undefined") return;

  const location = [46.08008535022743, 13.211890024964413];
  const map = L.map(mapElement).setView(location, 15);
  L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 18,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  }).addTo(map);
  L.marker(location).addTo(map);
})();
