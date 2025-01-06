<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from "vue";
import LoadingComponent from "./components/LoadingComponent.vue";
import AccountsComponent from "./components/AccountsComponent.vue";
import InvoicesComponent from "./components/InvoicesComponent.vue";
import { useLocaleStore } from "./stores/locale";

const locale = useLocaleStore();

type Tab = "accounts" | "invoices";

const isLoading = ref(true);
const tab = ref<Tab>("accounts");
const theme = ref<string>("dark");

const tabs = {
  accounts: AccountsComponent,
  invoices: InvoicesComponent,
};

const changeTab = (newTab: Tab) => {
  tab.value = newTab;
};

const currentTab = computed(() => tabs[tab.value]);

onMounted(() => {
  locale.fetch();

  setTimeout(() => {
    const { getSettings, onSettingsChange } = window as any;

    if (typeof getSettings === "undefined") return;
    if (typeof onSettingsChange === "undefined") return;

    getSettings().then((settings: any) => {
      theme.value = settings.display.theme;
    });

    onSettingsChange((settings: any) => {
      theme.value = settings.display.theme;
    });
  }, 1000);

  isLoading.value = false;
});

onUnmounted(() => {
  isLoading.value = true;
});
</script>

<template>
  <div class="flex flex-1 overflow-hidden" :data-theme="theme">
    <LoadingComponent v-if="isLoading" />
    <div
      class="relative flex flex-col flex-1 overflow-hidden bg-[#25262b] items-center subpixel-antialiased"
      v-else
    >
      <Transition name="scale" mode="out-in">
        <Component :is="currentTab" :key="tab" />
      </Transition>

      <div
        class="absolute bottom-[1.5rem] w-[95%] bg-[#25262b] text-gray-400 py-2 flex items-end justify-center gap-24 rounded-2xl border border-[#373A40]"
      >
        <div
          class="flex flex-col items-center justify-between gap-0.5 hover:text-gray-200 transition duration-150 ease-linear hover:cursor-pointer"
          :class="[tab === 'accounts' ? 'text-gray-200' : '']"
          @click.prevent="changeTab('accounts')"
        >
          <i class="fa-solid fa-building-columns text-2xl flex-1"></i>
          <span class="font-semibold">
            {{ locale.get("bank_app_title") }}
          </span>
        </div>
        <div
          class="flex flex-col items-center justify-between gap-0.5 hover:text-gray-200 transition duration-150 ease-linear hover:cursor-pointer"
          :class="[tab === 'invoices' ? 'text-gray-200' : '']"
          @click.prevent="changeTab('invoices')"
        >
          <i class="fa-solid fa-receipt text-2xl flex-1"></i>
          <span class="font-semibold">
            {{ locale.get("invoices_app_title") }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
