<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="text-h5 text-weight-medium q-mb-md">Help &amp; Documentation</div>

      <!-- Quick links -->
      <div class="row q-col-gutter-md q-mb-lg">
        <div class="col-6 col-md-3" v-for="link in quickLinks" :key="link.label">
          <a :href="link.url" target="_blank" rel="noopener noreferrer" >
            <q-card class="page-card cursor-pointer" clickable v-ripple>
              <q-card-section class="text-center q-pa-lg">
                <q-icon :name="link.icon" size="36px" color="primary" class="q-mb-sm" />
                <div class="text-subtitle2 text-weight-medium">{{ link.label }}</div>
                <div class="text-caption text-grey">{{ link.description }}</div>
              </q-card-section>
            </q-card>
          </a>
        </div>
      </div>

      <div class="row q-col-gutter-lg">
        <!-- FAQ -->
        <div class="col-12 col-md-8">
          <q-card class="page-card">
            <q-card-section>
              <div class="text-h6 q-mb-md">Frequently Asked Questions</div>
              <div class="text-body2 text-grey">No documentation available yet.</div>
            </q-card-section>
          </q-card>
        </div>

        <!-- Sidebar -->
        <div class="col-12 col-md-4">
          <q-card class="page-card q-mb-md">
            <q-card-section>
              <div class="text-subtitle1 text-weight-medium q-mb-sm">System Information</div>
              <q-list dense>
                <q-item v-for="info in systemInfo" :key="info.label">
                  <q-item-section>
                    <q-item-label class="text-caption text-grey">{{ info.label }}</q-item-label>
                  </q-item-section>
                  <q-item-section side>
                    <q-item-label>{{ info.value }}</q-item-label>
                  </q-item-section>
                </q-item>
              </q-list>
            </q-card-section>
          </q-card>

          <q-card class="page-card">
            <q-card-section>
              <div class="text-subtitle1 text-weight-medium q-mb-sm">More Help?</div>
              <q-btn outline color="primary" label="Open Issue on GitHub" icon="open_in_new" class="full-width q-mb-sm" 
              href="https://github.com/AbeonaSec/abeonasec-core/issues" target="_blank" rel="noopener noreferrer"/>
            </q-card-section>
          </q-card>
        </div>
      </div>
    </div>
  </q-page>
</template>

<script setup>
const quickLinks = [
  { label: 'Getting Started', description: 'Installation Guide', icon: 'rocket_launch', url:'https://github.com/AbeonaSec/abeonasec-core/blob/main/docs/Installation_Guide.md' },
  { label: 'Configuration', description: 'System and plugin settings', icon: 'tune', url:'' },
  { label: 'Changelog', description: 'Release notes and updates', icon: 'history', url:'https://github.com/AbeonaSec/abeonasec-core/tree/main/docs/updates' }
]

const systemInfo = [
  { label: 'Blank', value: 'for now' }
]
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
</style>