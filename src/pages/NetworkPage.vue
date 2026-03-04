<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="text-h5 text-weight-medium q-mb-md">Network</div>

      <!-- Summary cards -->
      <div class="row q-col-gutter-md q-mb-lg">
        <div class="col-6 col-md-3" v-for="stat in stats" :key="stat.label">
          <q-card class="page-card">
            <q-card-section class="text-center">
              <q-icon :name="stat.icon" size="28px" color="grey" class="q-mb-xs" />
              <div class="text-h5 text-weight-bold text-grey">—</div>
              <div class="text-caption text-grey">{{ stat.label }}</div>
            </q-card-section>
          </q-card>
        </div>
      </div>

      <!-- Tabbed panels -->
      <q-card class="page-card">
        <q-tabs v-model="activeTab" dense align="left" class="text-grey" active-color="primary" indicator-color="primary">
          <q-tab name="connections" label="Active Connections" icon="cable" />
          <q-tab name="traffic" label="Traffic" icon="swap_vert" />
          <q-tab name="interfaces" label="Interfaces" icon="settings_ethernet" />
        </q-tabs>
        <q-separator />
        <q-tab-panels v-model="activeTab">
          <q-tab-panel v-for="tab in ['connections', 'traffic', 'interfaces']" :key="tab" :name="tab">
            <div class="text-body2 text-grey">No data source connected</div>
          </q-tab-panel>
        </q-tab-panels>
      </q-card>
    </div>
  </q-page>
</template>

<script setup>
import { ref } from 'vue'

const activeTab = ref('connections')

const stats = [
  { label: 'Active Connections', icon: 'cable' },
  { label: 'Inbound Rate', icon: 'arrow_downward' },
  { label: 'Outbound Rate', icon: 'arrow_upward' },
  { label: 'Blocked Today', icon: 'block' }
]
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
</style>