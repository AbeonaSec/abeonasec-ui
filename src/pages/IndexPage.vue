<template>
  <q-page class="q-pa-lg">
    <div class="dashboard-container">
      <div class="text-h5 text-weight-medium q-mb-md">Overview</div>

      <div class="row q-col-gutter-lg">
        <div class="col-12 col-md-6" v-for="card in cards" :key="card.title">
          <q-card class="dashboard-card" clickable @click="$router.push(card.link)">
            <q-card-section class="row items-center justify-between">
              <div class="text-h6">{{ card.title }}</div>
              <q-icon :name="card.icon" size="24px" :color="card.color" />
            </q-card-section>
            <q-separator />
            <q-card-section class="text-body2 text-grey">
              No data source connected
            </q-card-section>
          </q-card>
        </div>
      </div>
    </div>
  </q-page>
</template>

<script setup>
const cards = [
  { title: 'System Health', icon: 'monitor_heart', color: 'positive', link: '/health' },
  { title: 'Threat Management', icon: 'shield', color: 'warning', link: '/threats' },
  { title: 'Logs', icon: 'receipt_long', color: 'info', link: '/logs' },
  { title: 'Plugins', icon: 'extension', color: 'accent', link: '/plugins' }
]
</script>

<style scoped>
.dashboard-container {
  max-width: 1200px;
  margin: 0 auto;
}

.dashboard-card {
  border-radius: 14px;
  transition: box-shadow 0.2s ease;
}

.dashboard-card:hover {
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.12);
}
</style>