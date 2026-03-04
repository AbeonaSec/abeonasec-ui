<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="text-h5 text-weight-medium q-mb-md">Threat Management</div>

      <!-- Filter bar -->
      <q-card class="page-card q-mb-lg">
        <q-card-section class="row items-center q-gutter-md">
          <q-input dense outlined placeholder="Search threats…" v-model="searchQuery" class="col-grow" disable>
            <template v-slot:prepend>
              <q-icon name="search" />
            </template>
          </q-input>
          <q-btn-toggle
            v-model="severityFilter"
            no-caps
            rounded
            unelevated
            toggle-color="primary"
            disable
            :options="[
              { label: 'All', value: 'all' },
              { label: 'Critical', value: 'critical' },
              { label: 'Warning', value: 'warning' },
              { label: 'Info', value: 'info' }
            ]"
          />
        </q-card-section>
      </q-card>

      <!-- Threats list -->
      <q-card class="page-card">
        <q-card-section class="row items-center justify-between">
          <div class="text-h6">Threats</div>
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
const severityFilter = ref('all')
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
</style>