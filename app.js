// Main application script for home page
document.addEventListener('DOMContentLoaded', function() {
    const container = document.getElementById('destinations-container');
    
    // Render destination cards
    destinations.forEach(destination => {
        const card = createDestinationCard(destination);
        container.appendChild(card);
    });
});

function createDestinationCard(destination) {
    const card = document.createElement('div');
    card.className = 'destination-card';
    card.setAttribute('data-destination-id', destination.id);
    
    card.innerHTML = `
        <img src="${destination.image}" alt="${destination.name}">
        <div class="destination-card-content">
            <h2>${destination.name}</h2>
            <p class="location">${destination.location}</p>
            <p class="description">${destination.description}</p>
            <p class="price">${destination.price}</p>
        </div>
    `;
    
    // Add click event to navigate to detail page
    card.addEventListener('click', function() {
        window.location.href = `detail.html?id=${destination.id}`;
    });
    
    return card;
}
