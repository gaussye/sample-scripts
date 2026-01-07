import { test, expect } from '@playwright/test';

test.describe('Travel Destination Application', () => {
  
  test('home page displays destination cards', async ({ page }) => {
    await page.goto('/');
    
    // Check if the page title is correct
    await expect(page).toHaveTitle(/Travel Destinations/);
    
    // Check if header is visible
    await expect(page.locator('header h1')).toHaveText('Explore Amazing Destinations');
    
    // Check if destination cards are rendered
    const cards = page.locator('.destination-card');
    await expect(cards).toHaveCount(6);
    
    // Verify first destination card content
    const firstCard = cards.first();
    await expect(firstCard.locator('h2')).toHaveText('Paris');
    await expect(firstCard.locator('.location')).toHaveText('France');
    await expect(firstCard.locator('.price')).toHaveText('$1,299');
  });

  test('clicking a destination card navigates to detail page', async ({ page }) => {
    await page.goto('/');
    
    // Wait for cards to be loaded
    await page.waitForSelector('.destination-card');
    
    // Click on the Paris card
    const parisCard = page.locator('.destination-card').filter({ hasText: 'Paris' });
    await parisCard.click();
    
    // Wait for navigation
    await page.waitForURL('**/detail.html?id=1');
    
    // Verify we're on the detail page
    expect(page.url()).toContain('detail.html?id=1');
  });

  test('detail page displays correct information for Paris', async ({ page }) => {
    await page.goto('/detail.html?id=1');
    
    // Check if the page title is correct
    await expect(page).toHaveTitle(/Destination Details/);
    
    // Check if back link is present
    const backLink = page.locator('.back-link');
    await expect(backLink).toBeVisible();
    await expect(backLink).toHaveText('← Back to Destinations');
    
    // Check destination details
    await expect(page.locator('.detail-content h1')).toHaveText('Paris');
    await expect(page.locator('.detail-content .location')).toHaveText('France');
    await expect(page.locator('.detail-content .price')).toHaveText('$1,299');
    
    // Check if full description is present
    const description = page.locator('.detail-content .description');
    await expect(description).toContainText('Paris, the capital of France');
    
    // Check if highlights section is present
    await expect(page.locator('.info-section h2')).toHaveText('Highlights');
    const highlights = page.locator('.info-section li');
    await expect(highlights).toHaveCount(5);
    await expect(highlights.first()).toContainText('Visit the iconic Eiffel Tower');
  });

  test('detail page displays correct information for Tokyo', async ({ page }) => {
    await page.goto('/detail.html?id=2');
    
    // Check destination details
    await expect(page.locator('.detail-content h1')).toHaveText('Tokyo');
    await expect(page.locator('.detail-content .location')).toHaveText('Japan');
    await expect(page.locator('.detail-content .price')).toHaveText('$1,599');
    
    // Check if full description is present
    const description = page.locator('.detail-content .description');
    await expect(description).toContainText('Tokyo, Japan\'s busy capital');
  });

  test('back link navigates to home page', async ({ page }) => {
    await page.goto('/detail.html?id=1');
    
    // Click the back link
    await page.locator('.back-link').click();
    
    // Wait for navigation
    await page.waitForURL('**/index.html');
    
    // Verify we're back on the home page
    expect(page.url()).toContain('index.html');
    await expect(page.locator('header h1')).toHaveText('Explore Amazing Destinations');
  });

  test('detail page handles invalid destination ID', async ({ page }) => {
    await page.goto('/detail.html?id=999');
    
    // Check if error message is displayed
    await expect(page.locator('.detail-content h1')).toHaveText('Destination not found');
    await expect(page.locator('.detail-content p')).toHaveText('The destination you are looking for does not exist.');
  });

  test('all destination cards are clickable and navigate correctly', async ({ page }) => {
    await page.goto('/');
    
    const destinations = [
      { name: 'Paris', id: 1 },
      { name: 'Tokyo', id: 2 },
      { name: 'New York', id: 3 },
      { name: 'Bali', id: 4 },
      { name: 'Rome', id: 5 },
      { name: 'Sydney', id: 6 }
    ];
    
    for (const dest of destinations) {
      // Go back to home page
      await page.goto('/');
      
      // Click on the destination card
      const card = page.locator('.destination-card').filter({ hasText: dest.name });
      await card.click();
      
      // Verify navigation
      await page.waitForURL(`**/detail.html?id=${dest.id}`);
      expect(page.url()).toContain(`detail.html?id=${dest.id}`);
      
      // Verify destination name on detail page
      await expect(page.locator('.detail-content h1')).toHaveText(dest.name);
    }
  });

  test('destination cards have proper data attributes', async ({ page }) => {
    await page.goto('/');
    
    // Check data attributes
    const firstCard = page.locator('.destination-card').first();
    await expect(firstCard).toHaveAttribute('data-destination-id', '1');
  });

  test('detail page images are displayed', async ({ page }) => {
    await page.goto('/detail.html?id=1');
    
    // Check if image is present
    const image = page.locator('.detail-content img');
    await expect(image).toBeVisible();
    await expect(image).toHaveAttribute('alt', 'Paris');
  });

  test('home page cards have hover effects', async ({ page }) => {
    await page.goto('/');
    
    const firstCard = page.locator('.destination-card').first();
    await firstCard.hover();
    
    // Card should be visible after hover
    await expect(firstCard).toBeVisible();
  });
});
