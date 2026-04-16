const API_BASE = "http://localhost:3000";

export const apiRequest = async (path, options = {}) => {
  let token = localStorage.getItem("access_token");
  
  const headers = {
    "Content-Type": "application/json",
    ...options.headers,
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  let response = await fetch(`${API_BASE}${path}`, { ...options, headers });

  // Handle Token Expiration
  if (response.status === 401) {
    const errorData = await response.clone().json();

    // Check if the backend specifically said the token expired
    if (errorData.errors?.includes("Token expired")) {
      const refreshed = await tryRefreshToken();
      
      if (refreshed) {
        // Retry the original request with the NEW token
        const newToken = localStorage.getItem("access_token");
        headers["Authorization"] = `Bearer ${newToken}`;
        return fetch(`${API_BASE}${path}`, { ...options, headers }).then(r => r.json());
      }
    }

    // If refresh failed or it was a different 401, logout
    localStorage.clear();
    if (window.location.pathname !== "/index.html") {
      window.location.href = "/index.html";
    }
  }

  return response.json();
};

/**
 * Calls Identity::SessionsController#refresh
 */
async function tryRefreshToken() {
  const refreshToken = localStorage.getItem("refresh_token");
  if (!refreshToken) return false;

  try {
    const response = await fetch(`${API_BASE}/session/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refreshToken })
    });

    if (response.ok) {
      const { data } = await response.json();
      // Update local storage with the new pair from Identity::RefreshToken
      localStorage.setItem("access_token", data.access_token);
      localStorage.setItem("refresh_token", data.refresh_token);
      return true;
    }
  } catch (err) {
    console.error("Refresh flow failed", err);
  }
  return false;
}
