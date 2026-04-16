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

async function handlePasskeyLogin() {
    const loginBtn = document.getElementById('passkey-login');
    const originalContent = loginBtn.innerHTML;

    try {
        // 1. UI State: Show loading
        loginBtn.disabled = true;
        loginBtn.innerHTML = 'Checking device...';

        // 2. Fetch challenge from Rails
        // We expect { publicKey: {...}, challenge_id: "..." }
        const response = await apiRequest("/passkeys/login_options", {
            method: "POST"
        });

        // 3. Prepare options for the browser
        // Use the native parse method to handle Base64URL to ArrayBuffer conversion
        const publicKey = PublicKeyCredential.parseRequestOptionsFromJSON(response.publicKey);

        // 4. Trigger the biometric/security key prompt
        const assertion = await navigator.credentials.get({ 
            publicKey,
            // optional: 'mediation: "required"' forces the selector to appear
            mediation: "optional" 
        });

        if (!assertion) throw new Error("No credential returned");

        // 5. Send the assertion back to Rails for verification
        loginBtn.innerHTML = 'Verifying...';
        const verifyRes = await apiRequest("/passkeys/login", {
            method: "POST",
            body: JSON.stringify({
                assertion: assertion.toJSON(),
                challenge_id: response.challenge_id
            })
        });

        // 6. Handle successful login
        if (verifyRes.data?.access_token) {
            localStorage.setItem("access_token", verifyRes.data.access_token);
            localStorage.setItem("refresh_token", verifyRes.data.refresh_token);
            window.location.href = "/profile.html";
        } else {
            throw new Error(verifyRes.errors?.join(", ") || "Login failed");
        }

    } catch (err) {
        console.error("Passkey Login Error:", err);
        alert(err.message || "Passkey login failed. Please try again or use your password.");
    } finally {
        // Reset UI
        loginBtn.disabled = false;
        loginBtn.innerHTML = originalContent;
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

  document.getElementById('passkey-login')?.addEventListener('click', (e) => {
    e.preventDefault(); // Prevent any form nesting issues
    handlePasskeyLogin();
  });
});
