<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="text-h5 text-weight-medium q-mb-md">System Health</div>

      <!-- Resource gauges -->
      <div class="row q-col-gutter-md q-mb-lg">
        <div class="col-6 col-md-3" v-for="metric in metrics" :key="metric.label">
          <q-card class="page-card">
            <q-card-section class="text-center">
              <q-circular-progress
                :value="0"
                size="80px"
                :thickness="0.15"
                color="grey-4"
                track-color="grey-3"
                class="q-mb-sm"
              >
                <span class="text-subtitle2 text-grey">—</span>
              </q-circular-progress>
              <div class="text-subtitle2 q-mt-xs">{{ metric.label }}</div>
            </q-card-section>
          </q-card>
        </div>
      </div>

      <!-- Services -->
      <q-card class="page-card">
        <q-card-section class="row items-center justify-between">
          <div class="text-h6">Services</div>
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
const metrics = [
  { label: 'CPU' },
  { label: 'Memory' },
  { label: 'Disk' },
  { label: 'Network' }
]
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
</style>