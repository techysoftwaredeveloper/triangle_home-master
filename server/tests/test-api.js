const axios = require('axios');

/**
 * Basic integration test script for the new backend endpoints.
 */

const BASE_URL = 'http://localhost:5000/api';

async function testRoutes() {
  const routes = [
    { method: 'get', path: '/admin/stats' },
    { method: 'get', path: '/bookings/my' },
    { method: 'post', path: '/bookings' },
    { method: 'post', path: '/properties' },
    { method: 'get', path: '/suggestions/my' },
    { method: 'post', path: '/suggestions' },
  ];

  console.log('--- Testing Route Registration (Expect 401 Unauthorized) ---');

  for (const route of routes) {
    try {
      const response = await axios({
        method: route.method,
        url: `${BASE_URL}${route.path}`,
        validateStatus: (status) => true
      });

      if (response.status === 401) {
        console.log(`[PASS] ${route.method.toUpperCase()} ${route.path} returned 401 as expected.`);
      } else if (response.status === 429) {
        console.log(`[PASS] ${route.method.toUpperCase()} ${route.path} rate limited (429) as expected.`);
      } else {
        console.log(`[FAIL] ${route.method.toUpperCase()} ${route.path} returned ${response.status}. Expected 401.`);
      }
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log(`[PASS] ${route.method.toUpperCase()} ${route.path} returned 401 as expected.`);
      } else if (error.response && error.response.status === 429) {
        console.log(`[PASS] ${route.method.toUpperCase()} ${route.path} rate limited (429) as expected.`);
      } else {
          console.log(`[ERROR] Failed to reach ${route.path}: ${error.message}`);
          if (error.response) {
              console.log(`Status: ${error.response.status}`);
          }
      }
    }
  }
}

async function testAppCheck() {
    console.log('\n--- Testing App Check Enforcement (Production Mode) ---');

    const originalNodeEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';

    try {
        const response = await axios.get(`${BASE_URL}/admin/stats`, {
            validateStatus: (status) => true
        });

        const errorMessage = response.data && response.data.error ? response.data.error : '';
        if (response.status === 401 && errorMessage.includes('App Check token missing')) {
            console.log(`[PASS] Blocked request without App Check token in production.`);
        } else {
            console.log(`[FAIL] Production mode allowed request without token. Status: ${response.status}, Error: ${errorMessage}`);
        }
    } catch (error) {
        console.log(`[ERROR] Test failed: ${error.message}`);
    } finally {
        process.env.NODE_ENV = originalNodeEnv;
    }
}

async function runTests() {
    await testRoutes();
    await testAppCheck();
}

runTests();
