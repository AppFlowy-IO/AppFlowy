<script lang="ts">
  import Greet from './lib/Greet.svelte'
</script>

<main class="container">
  <h1>Welcome to Tauri!</h1>

  <div class="row">
    <Greet />
  </div>

</main>

<style>
  .logo.vite:hover {
    filter: drop-shadow(0 0 2em #747bff);
  }

  .logo.svelte:hover {
    filter: drop-shadow(0 0 2em #ff3e00);
  }
</style>