<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="row items-center justify-between q-mb-md">
        <div class="text-h5 text-weight-medium">Plugins</div>
        <q-btn flat dense icon="add" label="Install Plugin" disable />
      </div>

      <!-- Filter chips -->
      <div class="row q-gutter-sm q-mb-lg">
        <q-chip clickable :outline="pluginFilter !== 'all'" :color="pluginFilter === 'all' ? 'primary' : undefined" :text-color="pluginFilter === 'all' ? 'white' : undefined" @click="pluginFilter = 'all'">All</q-chip>
        <q-chip clickable :outline="pluginFilter !== 'active'" @click="pluginFilter = 'active'">Active</q-chip>
        <q-chip clickable :outline="pluginFilter !== 'disabled'" @click="pluginFilter = 'disabled'">Disabled</q-chip>
      </div>

      <!-- Plugin grid -->
      <q-card class="page-card">
        <q-card-section class="row items-center justify-between">
          <div class="text-h6">Installed Plugins</div>
        </q-card-section>
        <q-separator />
        <q-card-section class="text-body2 text-grey">
          No data source connected
        </q-card-section>
      </q-card>
    </div>
  </q-page>
</template>

<script setup>
import { ref } from 'vue'

const pluginFilter = ref('all')
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
</style>