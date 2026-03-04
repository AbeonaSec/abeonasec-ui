<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="row items-center justify-between q-mb-md">
        <div class="text-h5 text-weight-medium">Logs</div>
        <q-btn flat dense icon="file_download" label="Export" disable />
      </div>

      <!-- Filter bar -->
      <q-card class="page-card q-mb-lg">
        <q-card-section class="row items-center q-gutter-md">
          <q-input dense outlined placeholder="Search logs…" v-model="searchQuery" class="col-grow" disable>
            <template v-slot:prepend>
              <q-icon name="search" />
            </template>
          </q-input>
          <q-select v-model="levelFilter" :options="['All', 'ERROR', 'WARN', 'INFO', 'DEBUG']" dense outlined label="Level" style="min-width: 120px;" disable />
          <q-select v-model="sourceFilter" :options="['All']" dense outlined label="Source" style="min-width: 180px;" disable />
        </q-card-section>
      </q-card>

      <!-- Logs table -->
      <q-card class="page-card">
        <q-card-section class="row items-center justify-between">
          <div class="text-h6">Log Entries</div>
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

const searchQuery = ref('')
const levelFilter = ref('All')
const sourceFilter = ref('All')
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
</style>