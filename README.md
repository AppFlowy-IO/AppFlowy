// authProvider.ts (or your custom auth provider file)

import { AuthProvider } from "@refinedev/core";

// Define a simple structure for your user identity data
interface UserIdentity {
    id: number;
    name: string;
    email: string;
    // Add other fields your app uses
}

const authProvider: AuthProvider = {
    login: async ({ email, password }) => {
        // 1. Send credentials to your backend API
        // This is a placeholder for your actual API call (e.g., using axios/fetch)
        const response = await fetch("YOUR_API_BASE_URL/auth/login", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email, password }),
        });

        const data = await response.json();

        if (response.ok && data.token) {
            // 2. Store the token on successful login
            localStorage.setItem("authToken", data.token);
            
            // Success response
            return {
                success: true,
                redirectTo: "/", // Redirect to the home page
            };
        }
        
        // Failed login attempt
        return {
            success: false,
            error: new Error(data.message || "Login failed. Check your credentials."),
        };
    },

    logout: async (params) => {
        // Clear the token and any user data
        localStorage.removeItem("authToken");
        localStorage.removeItem("user");

        // Success response
        return {
            success: true,
            redirectTo: "/login", // Always redirect to the login page
        };
    },

    checkAuth: async (params) => {
        const token = localStorage.getItem("authToken");
        
        if (token) {
            // User is authenticated
            return {
                authenticated: true,
            };
        }

        // User is not authenticated, redirect to login
        return {
            authenticated: false,
            redirectTo: "/login",
        };
    },

    getIdentity: async () => {
        const user = localStorage.getItem("user");
        
        if (user) {
            // Return parsed user identity
            return JSON.parse(user) as UserIdentity;
        }
        
        // If identity is not found, return null or throw error if session is strictly required
        return null;
    },

    // 🌟 FIX FOR THE INFINITE LOOP BUG (Issue #6997) 🌟
    onError: async (error) => {
        // Ensure we can extract a status code from the error object
        const status = (error as any)?.statusCode || (error as any)?.response?.status;

        // Check for Unauthorized (401) or Forbidden (403) status codes
        if (status === 401 || status === 403) {
            // The crucial fix is returning `{ logout: true }`.
            // This instructs Refine's core to call the 'logout' method, 
            // which handles clearing the session and redirecting, preventing the loop.
            return {
                logout: true,
                error: new Error("Session Expired. Please log in again."),
            };
        }

        // For all other errors, just report them without logging out or redirecting
        return {};
    },
};

export default authProvider;