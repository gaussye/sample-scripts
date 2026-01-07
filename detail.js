// Detail page script
document.addEventListener('DOMContentLoaded', function() {
    const container = document.getElementById('detail-container');
    
    // Get destination ID from URL parameters
    const urlParams = new URLSearchParams(window.location.search);
    const destinationId = parseInt(urlParams.get('id'));
    
    // Find the destination
    const destination = destinations.find(d => d.id === destinationId);
    
    if (destination) {
        renderDestinationDetails(destination, container);
    } else {
        container.innerHTML = '<h1>Destination not found</h1><p>The destination you are looking for does not exist.</p>';
    }
});

function renderDestinationDetails(destination, container) {
    container.innerHTML = `
        <img src="${destination.image}" alt="${destination.name}">
        <h1>${destination.name}</h1>
        <p class="location">${destination.location}</p>
        <span class="price">${destination.price}</span>
        <p class="description">${destination.fullDescription}</p>
        
        <div class="info-section">
            <h2>Highlights</h2>
            <ul>
                ${destination.highlights.map(highlight => `<li>${highlight}</li>`).join('')}
            </ul>
        </div>
    `;
}
