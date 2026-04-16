import { apiRequest } from './api.js';
/**
 * INITIALIZATION
 * Check if the user is allowed to be here.
 */
async function initProfile() {
  const token = localStorage.getItem("access_token");
  
  if (!token) {
    window.location.href = "/index.html";
    return;
  }

  // Hide Passkey UI if the browser doesn't support WebAuthn
  if (!window.PublicKeyCredential) {
    const passkeySection = document.getElementById('passkey-section');
    if (passkeySection) passkeySection.classList.add('hidden');
  }

  loadProfileData();
}

/**
 * DATA LOADING
 * Fetch user info from the Rails backend
 */
async function loadProfileData() {
  const profileContainer = document.getElementById('profile-content');
  
  const result = await apiRequest("/profile");
  
  if (result.data) {
    profileContainer.innerHTML = `
      <p class="text-sm text-slate-600"><strong>Email:</strong> ${result.data.email}</p>
      <p class="text-sm text-slate-600"><strong>Internal ID:</strong> ${result.data.id}</p>
      <p class="text-sm text-slate-600"><strong>Account Created:</strong> ${new Date(result.data.created_at).toLocaleDateString()}</p>
    `;
  } else {
    profileContainer.innerHTML = `<p class="text-red-500 text-sm">Error loading profile data.</p>`;
  }
}

/**
 * SECURITY: Passkey Registration
 * Registers the current device as a Passkey
 */
async function handleRegisterPasskey() {

  const msg = document.getElementById('passkey-msg');

  try {

    msg.className = "mt-2 text-xs text-center text-blue-600";
    msg.textContent = "Interact with your device's biometric prompt...";

    const optionsJSON = await apiRequest("/passkeys/options");
    
    // Native browser method to convert your Rails JSON into binary
    const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(optionsJSON);

    // Native browser prompt
    const credential = await navigator.credentials.create({ publicKey });

    // Convert the result back to JSON to send to Rails
    const credentialJSON = credential.toJSON();

    await apiRequest("/passkeys", {
      method: "POST",
      body: JSON.stringify(credentialJSON)
    });
    msg.className = "mt-2 text-xs text-center text-green-600";
    msg.textContent = "Passkey registered! You can now log in using biometrics.";
  } catch (err) {
    console.error("Registration failed", err);

    if (err.name === 'NotAllowedError') {
        msg.textContent = "Registration cancelled or timed out.";
    } else {
        msg.textContent = "Registration failed. Ensure you are on HTTPS or localhost.";
    }
  }
}

/**
 * SECURITY: Password Update
 */
async function handlePasswordChange(e) {
  e.preventDefault();
  const msg = document.getElementById('password-msg');
  const formData = new FormData(e.target);
  const body = Object.fromEntries(formData);

  const res = await apiRequest("/profile/change_password", {
    method: "PATCH",
    body: JSON.stringify(body)
  });

  if (res.message) {
    msg.className = "mt-2 text-xs text-center text-green-600";
    msg.textContent = res.message;
    e.target.reset();
  } else {
    msg.className = "mt-2 text-xs text-center text-red-600";
    msg.textContent = res.errors?.join(", ") || "Failed to update password";
  }
}

/**
 * SESSION: Logout
 */
async function handleLogout() {
  const refresh_token = localStorage.getItem("refresh_token");
  
  await apiRequest("/logout", {
    method: "DELETE",
    body: JSON.stringify({ refresh_token })
  });

  localStorage.clear();
  window.location.href = "/index.html";
}

// Event Listeners
window.addEventListener('DOMContentLoaded', () => {
  initProfile();

  document.getElementById('logout-btn')?.addEventListener('click', handleLogout);
  document.getElementById('password-form')?.addEventListener('submit', handlePasswordChange);
  document.getElementById('register-passkey-btn')?.addEventListener('click', handleRegisterPasskey);
});

