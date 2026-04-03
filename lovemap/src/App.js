// React + Mapbox GL JS Interactive Relationship Map
// Whimsical + Moody Style with Memory Popups and Planned Trip Section + Filters + Sidebar + Custom Images + Swan Icon + Image Gallery

import React, { useEffect, useRef, useState } from "react";
import mapboxgl from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";

mapboxgl.accessToken = process.env.REACT_APP_MAPBOX_TOKEN;

const tripData = {
  past: [
    {
      name: "Crestone, CO",
      coords: [-105.6997, 37.9966],
      date: "August 2024",
      memory: "We watched the stars together under the clearest sky either of us had ever seen.",
      tag: "Stargazing",
      lyric: "I think he did it but I just can't prove it — we vanished like a phantom in the night",
      images: ["images/crestone.jpg", "images/crestone_2.jpg"]
    },
    {
      name: "Crested Butte, CO",
      coords: [-106.9878, 38.8697],
      date: "July 4, 2024",
      memory: "Wildflowers, fireworks, and laughter in the mountains.",
      tag: "Wildflowers",
      lyric: "I once believed love would be burning red, but it's golden like daylight"
    },
    {
      name: "Colorado Springs, CO",
      coords: [-104.8214, 38.8339],
      date: "September 2024",
      memory: "We saw the sky fill with colors and drift with the wind in hot air balloons.",
      tag: "Hot Air Balloons",
      lyric: "Up in the clouds, high above the noise",
      images: ["images/colorado_springs.jpg", "images/colorado_springs_2.jpg"]
    },
    {
      name: "Lost Creek Wilderness, CO",
      coords: [-105.4203, 39.2502],
      date: "June 2024",
      memory: "Our first backpacking trip — dirt, pine, and love.",
      tag: "Backpacking",
      lyric: "We found wonderland — you and I got lost in it",
      images: ["images/lost_creek.jpg"]
    },
    {
      name: "Sterne Park, Littleton, CO",
      coords: [-105.0051, 39.6101],
      date: "November 2023",
      memory: "Where it all really started, where our hearts began to sync.",
      tag: "First Date",
      lyric: "This love left a permanent mark"
    },
    {
      name: "Carpenter Park, Thornton, CO",
      coords: [-104.9593, 39.9253],
      date: "July 2024",
      memory: "Where we made it official. Our little anniversary universe.",
      tag: "Anniversary",
      lyric: "I remember it all too well",
      images: ["images/carpenter_park.jpg", "images/carpenter_park_2.jpg"]
    },
    {
      name: "City Park, Denver, CO",
      coords: [-104.9493, 39.7475],
      date: "December 2023",
      memory: "Our first real date — a picnic in the park followed by a swan boat ride across the lake.",
      tag: "Picnic Date",
      lyric: "You are the best thing that's ever been mine",
      images: ["images/city_park.jpg", "images/city_park_2.jpg"],
      icon: "images/swan-icon.svg"
    }
  ],
  future: [
    {
      name: "Beijing, China",
      coords: [116.4074, 39.9042],
      note: "Upcoming adventure to the Great Wall and Forbidden City",
      tag: "Planned Trip"
    },
    {
      name: "Vietnam",
      coords: [108.2772, 14.0583],
      note: "Cafés, lanterns, and riverside memories",
      tag: "Dream Destination"
    },
    {
      name: "Australia",
      coords: [133.7751, -25.2744],
      note: "Our future home under southern skies",
      tag: "Future Home"
    },
    {
      name: "Argentina",
      coords: [-63.6167, -38.4161],
      note: "Wine country, glaciers, and dancing late into the night",
      tag: "Dream Destination"
    },
    {
      name: "Oregon, USA",
      coords: [-120.5542, 43.8041],
      note: "Rainy forests, coastlines, and cozy cabins",
      tag: "Dream Destination"
    },
    {
      name: "Zion National Park, UT",
      coords: [-113.0263, 37.2982],
      note: "Hiking red canyons hand-in-hand",
      tag: "Dream Destination"
    },
    {
      name: "Yosemite National Park, CA",
      coords: [-119.5383, 37.8651],
      note: "Granite giants, waterfalls, and timeless beauty",
      tag: "Dream Destination"
    }
  ]
};

const Map = () => {
  const mapContainer = useRef(null);
  const map = useRef(null);
  const markersRef = useRef([]);
  const [filters, setFilters] = useState({ past: true, future: true });
  const [sidebarOpen, setSidebarOpen] = useState(true);

  useEffect(() => {
    if (map.current) return;

    map.current = new mapboxgl.Map({
      container: mapContainer.current,
      style: "mapbox://styles/mapbox/dark-v10",
      center: [-105.0, 39.6],
      zoom: 6
    });
  }, []);

  useEffect(() => {
    if (!map.current) return;

    map.current.resize();

    markersRef.current.forEach(marker => marker.remove());
    markersRef.current = [];

    if (filters.past) {
      tripData.past.forEach((trip) => {
        const imageGallery = trip.images
          ? `<div style='display: flex; gap: 5px; overflow-x: auto; margin-top: 10px;'>
              ${trip.images.map(src => `<img src="${src}" alt="${trip.name}" style="width: 100px; height: auto; border-radius: 8px;" />`).join("")}
            </div>`
          : "";

        const popup = new mapboxgl.Popup({ offset: 25 }).setHTML(
          `<div style='max-width: 240px; font-family: "Comic Sans MS", cursive, sans-serif; background: #fff0f5; border-radius: 10px; padding: 10px; color: #333;'>
            <h3 style='margin: 0 0 5px;'>${trip.name}</h3>
            <p style='margin: 0 0 5px;'><strong>${trip.date}</strong></p>
            <p style='margin: 0 0 5px;'>${trip.memory}</p>
            <em style='color: #8e44ad;'>“${trip.lyric}”</em>
            ${imageGallery}
          </div>`
        );

        const marker = new mapboxgl.Marker(
          trip.icon
            ? {
                element: (() => {
                  const el = document.createElement("div");
                  el.style.backgroundImage = `url(${trip.icon})`;
                  el.style.width = "32px";
                  el.style.height = "32px";
                  el.style.backgroundSize = "contain";
                  el.style.backgroundRepeat = "no-repeat";
                  return el;
                })()
              }
            : { color: "#ff69b4" }
        )
          .setLngLat(trip.coords)
          .setPopup(popup)
          .addTo(map.current);

        markersRef.current.push(marker);
      });
    }

    if (filters.future) {
      tripData.future.forEach((trip) => {
        const popup = new mapboxgl.Popup({ offset: 25 }).setHTML(
          `<div style='max-width: 200px'>
            <h3>${trip.name}</h3>
            <p>${trip.note}</p>
          </div>`
        );

        const marker = new mapboxgl.Marker({ color: "#a0e7e5" })
          .setLngLat(trip.coords)
          .setPopup(popup)
          .addTo(map.current);

        markersRef.current.push(marker);
      });
    }
  }, [filters]);

  useEffect(() => {
    if (map.current) map.current.resize();
  }, [sidebarOpen]);

  return (
    <div style={{ display: "flex", height: "100vh", width: "100%" }}>
      {sidebarOpen && (
        <div style={{ width: "250px", background: "#1e1e2f", color: "white", padding: "20px", overflowY: "auto" }}>
          <button
            onClick={() => setSidebarOpen(false)}
            style={{ marginBottom: "10px", background: "#444", color: "white", border: "none", padding: "5px 10px", borderRadius: "5px", cursor: "pointer" }}
          >
            Hide Sidebar
          </button>
          <h2>Gnocchi's Journey</h2>
          <p>Welcome to our map, where every pin is a piece of our love story.</p>
          <hr style={{ border: "1px solid #444" }} />
          <label>
            <input
              type="checkbox"
              checked={filters.past}
              onChange={() => setFilters({ ...filters, past: !filters.past })}
            />
            &nbsp; Past Adventures
          </label>
          <br />
          <label>
            <input
              type="checkbox"
              checked={filters.future}
              onChange={() => setFilters({ ...filters, future: !filters.future })}
            />
            &nbsp; Future Dreams
          </label>
        </div>
      )}
      {!sidebarOpen && (
        <button
          onClick={() => setSidebarOpen(true)}
          style={{ position: "absolute", top: "10px", left: "10px", zIndex: 1, background: "#1e1e2f", color: "white", border: "none", padding: "8px 12px", borderRadius: "5px", cursor: "pointer" }}
        >
          Show Sidebar
        </button>
      )}
      <div ref={mapContainer} style={{ flex: 1 }} />
    </div>
  );
};

export default Map;

