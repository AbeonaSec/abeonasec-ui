<template>
  <q-layout view="hHh Lpr lFf">
    <q-header elevated   :class="$q.dark.isActive ? 'bg-black-10 text-white' : 'bg-black text-white'"
>
      <q-toolbar>
        <q-btn
          flat
          dense
          round
          icon="menu"
          aria-label="Menu"
          @click="toggleLeftDrawer"
        />

        <q-toolbar-title>
          <q-btn
            flat
            dense
            label="Abeona Security"
            to="/"
          />
        </q-toolbar-title>
        
        <!-- Dark/Light mode toggle -->
        <q-btn
          flat
          round
          dense
          :icon="$q.dark.isActive ? 'dark_mode' : 'light_mode'"
          @click="$q.dark.toggle()"
          aria-label="Toggle dark mode"
        />

        <div>v1.0.0</div>
      </q-toolbar>
    </q-header>

    <q-drawer
      v-model="leftDrawerOpen"
      show-if-above
      bordered
    >
      <q-list>
        <q-item-label
          header
        >
          Navigation
        </q-item-label>

        <template v-for="(item, index) in linksList" :key="index">
          <q-item clickable v-ripple :to="item.link">
            <q-item-section avatar>
              <q-icon :name="item.icon" />
            </q-item-section>
            <q-item-section>
              {{ item.title }}
              <q-item-label caption>
                {{ item.caption }}
              </q-item-label>
            </q-item-section>
          </q-item>
          <q-separator/>
        </template>
      </q-list>
    </q-drawer>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup>
import { ref } from 'vue'

const linksList = [
  {
    title: 'Health',
    caption: 'System status and resource utilization',
    icon: 'favorite',
    // link: import('pages/HealthPage.vue'),
    link: '/health', // :to expects a route path, not a file path
    separator: true
  },
  {
    title: 'Threat Management',
    caption: 'Active threats and mitigation actions',
    icon: 'code',
    // we should be able to just use the pathway as the link to the new page
    link: '/threats',
    separator: true
  },
  {
    title: 'Logs',
    caption: 'Security events and audit trails',
    icon: 'chat',
    link: '/logs',
    separator: true

  },
  {
    title: 'Plugins',
    caption: 'View and install plugins',
    icon: 'lock',
    link: '/plugins',
    separator: true
  },
  {
    title: 'Network',
    caption: 'Traffic monitoring and connection status',
    icon: 'record_voice_over',
    link: '/network',
    separator: true
  },
  {
    title: 'Help',
    caption: 'Documentation and support resources',
    icon: 'rss_feed',
    link: '/help',
    separator: true
  }
]

const leftDrawerOpen = ref(false)

function toggleLeftDrawer () {
  leftDrawerOpen.value = !leftDrawerOpen.value
}
</script>