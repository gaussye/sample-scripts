// Sample destination data
const destinations = [
    {
        id: 1,
        name: "Paris",
        location: "France",
        description: "The City of Light offers iconic landmarks, world-class museums, and romantic atmosphere.",
        fullDescription: "Paris, the capital of France, is a major European city and a global center for art, fashion, gastronomy and culture. Its 19th-century cityscape is crisscrossed by wide boulevards and the River Seine. Beyond such landmarks as the Eiffel Tower and the 12th-century, Gothic Notre-Dame cathedral, the city is known for its cafe culture and designer boutiques along the Rue du Faubourg Saint-Honoré.",
        price: "$1,299",
        image: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&h=600&fit=crop",
        highlights: [
            "Visit the iconic Eiffel Tower",
            "Explore the Louvre Museum",
            "Walk along the Champs-Élysées",
            "Experience Montmartre and Sacré-Cœur",
            "Cruise on the Seine River"
        ]
    },
    {
        id: 2,
        name: "Tokyo",
        location: "Japan",
        description: "A vibrant metropolis blending traditional culture with cutting-edge technology and entertainment.",
        fullDescription: "Tokyo, Japan's busy capital, mixes the ultramodern and the traditional, from neon-lit skyscrapers to historic temples. The opulent Meiji Shinto Shrine is known for its towering gate and surrounding woods. The Imperial Palace sits amid large public gardens. The city's many museums offer exhibits ranging from classical art to a reconstructed kabuki theater.",
        price: "$1,599",
        image: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&h=600&fit=crop",
        highlights: [
            "Experience traditional temples and shrines",
            "Explore vibrant neighborhoods like Shibuya and Harajuku",
            "Enjoy authentic Japanese cuisine",
            "Visit Tokyo Skytree for panoramic views",
            "Discover the peaceful Meiji Shrine"
        ]
    },
    {
        id: 3,
        name: "New York",
        location: "USA",
        description: "The Big Apple - a dynamic city known for its skyline, entertainment, and diverse culture.",
        fullDescription: "New York City comprises 5 boroughs sitting where the Hudson River meets the Atlantic Ocean. At its core is Manhattan, a densely populated borough that's among the world's major commercial, financial and cultural centers. Its iconic sites include skyscrapers such as the Empire State Building and sprawling Central Park. Broadway theater is staged in neon-lit Times Square.",
        price: "$999",
        image: "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800&h=600&fit=crop",
        highlights: [
            "See the Statue of Liberty",
            "Walk through Central Park",
            "Experience Times Square",
            "Visit world-class museums",
            "Explore diverse neighborhoods"
        ]
    },
    {
        id: 4,
        name: "Bali",
        location: "Indonesia",
        description: "A tropical paradise featuring stunning beaches, ancient temples, and lush landscapes.",
        fullDescription: "Bali is an Indonesian island known for its forested volcanic mountains, iconic rice paddies, beaches and coral reefs. The island is home to religious sites such as cliffside Uluwatu Temple. To the south, the beachside city of Kuta has lively bars, while Seminyak, Sanur and Nusa Dua are popular resort towns. The island is also known for its yoga and meditation retreats.",
        price: "$899",
        image: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800&h=600&fit=crop",
        highlights: [
            "Relax on beautiful beaches",
            "Visit ancient temples",
            "Experience traditional Balinese culture",
            "Explore rice terraces",
            "Enjoy yoga and wellness retreats"
        ]
    },
    {
        id: 5,
        name: "Rome",
        location: "Italy",
        description: "The Eternal City filled with ancient history, stunning architecture, and delicious cuisine.",
        fullDescription: "Rome, Italy's capital, is a sprawling, cosmopolitan city with nearly 3,000 years of globally influential art, architecture and culture on display. Ancient ruins such as the Forum and the Colosseum evoke the power of the former Roman Empire. Vatican City, headquarters of the Roman Catholic Church, has St. Peter's Basilica and the Vatican Museums, which house masterpieces such as Michelangelo's Sistine Chapel frescoes.",
        price: "$1,199",
        image: "https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&h=600&fit=crop",
        highlights: [
            "Explore the ancient Colosseum",
            "Visit Vatican City and St. Peter's Basilica",
            "Throw a coin in the Trevi Fountain",
            "Walk through the Roman Forum",
            "Enjoy authentic Italian cuisine"
        ]
    },
    {
        id: 6,
        name: "Sydney",
        location: "Australia",
        description: "A harbor city known for its Opera House, beautiful beaches, and outdoor lifestyle.",
        fullDescription: "Sydney, capital of New South Wales and one of Australia's largest cities, is best known for its harbourfront Sydney Opera House, with a distinctive sail-like design. Massive Darling Harbour and the smaller Circular Quay port are hubs of waterside life, with the arched Harbour Bridge and esteemed Royal Botanic Garden nearby. Sydney Tower's outdoor platform, the Skywalk, offers 360-degree views of the city and suburbs.",
        price: "$1,499",
        image: "https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&h=600&fit=crop",
        highlights: [
            "See the iconic Opera House",
            "Climb the Harbour Bridge",
            "Relax at Bondi Beach",
            "Explore the Royal Botanic Garden",
            "Experience vibrant city culture"
        ]
    }
];
