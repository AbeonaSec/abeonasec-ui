const routes = [
  {
    path: '/',
    component: () => import('layouts/MainLayout.vue'),
    children: [
      { path: '', component: () => import('pages/IndexPage.vue') },
      { path: 'health', component: () => import('pages/HealthPage.vue') },
      { path: 'threats', component: () => import('pages/ThreatManagementPage.vue') },
      { path: 'logs', component: () => import('pages/LogsPage.vue') },
      { path: 'plugins', component: () => import('pages/PluginsPage.vue') },
      { path: 'network', component: () => import('pages/NetworkPage.vue') },
      { path: 'help', component: () => import('pages/HelpPage.vue') }
    ]
  },
  // Always leave this as last one,
  // but you can also remove it
  {
    path: '/:catchAll(.*)*',
    component: () => import('pages/ErrorNotFound.vue')
  }
]

export default routes
