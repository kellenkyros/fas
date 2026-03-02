import { apiRequest } from './api.js';

/**
 * SIGNUP: Matches Identity::UsersController#signup
 */
async function handleSignup(email, password) {
  const data = await apiRequest("/signup", {
    method: "POST",
    body: JSON.stringify({ user: { email, password, password_confirmation: password } })
  });
  
  if (data.user) {
    alert("Signup successful! Please log in.");
    location.reload(); // Refresh to show login form
  } else {
    alert("Signup Error: " + (data.errors?.join(", ") || "Unknown error"));
  }
}

/**
 * PASSWORD LOGIN: Matches Identity::SessionsController#create
 */

async function handleLogin(email, password) {
  const response = await apiRequest("/login", {
    method: "POST",
    body: JSON.stringify({ email, password })
  });

  // Access the nested 'data' object from your JSON response
  const authData = response.data;

  if (authData && authData.access_token) {
    console.log("Token received:", authData.access_token);
    
    localStorage.setItem("access_token", authData.access_token);
    localStorage.setItem("refresh_token", authData.refresh_token);
    
    window.location.href = "/profile.html";
  } else {
    // Handle the case where 'data' isn't there (likely an error response)
    const errorMsg = response.errors?.join(", ") || "Invalid credentials";
    alert("Login Error: " + errorMsg);
  }
}

/**
 * MAGIC LINK: Matches Identity::LoginAttemptsController#create & #subscribe
 */
async function handleMagicLink(email) {
  const data = await apiRequest("/send_magic_login", {
    method: "POST",
    body: JSON.stringify({ email })
  });

  if (data.attempt_id) {
    // Show waiting UI
    document.getElementById('login-box').classList.add('hidden');
    document.getElementById('waiting-box').classList.remove('hidden');

    // 1. Desktop listens for the "Ping" (SSE)
    const sse = new EventSource(`http://localhost:3000/login_attempts/${data.attempt_id}/subscribe`);

    // Listening for sse.write(message, event: "authorized")
    sse.addEventListener("authorized", (event) => {
      const payload = JSON.parse(event.data);
      if (payload.status === "success") {
        localStorage.setItem("access_token", payload.token);
        sse.close();
        window.location.href = "/profile.html";
      }
    });

    sse.onerror = () => {
      console.error("SSE Connection lost");
      sse.close();
    };
  }
}

// Attach to UI
window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('auth-form')?.addEventListener('submit', (e) => {
    e.preventDefault();
    const mode = e.submitter.dataset.mode;
    const email = e.target.email.value;
    const password = e.target.password.value;

    if (mode === 'signup') handleSignup(email, password);
    else if (mode === 'login') handleLogin(email, password);
    else if (mode === 'magic') handleMagicLink(email);
  });
});
