<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { EventBus } from "@/event-bus";
import { useLocaleStore } from "@/stores/locale";
import AccountHistoryComponent from "./AccountHistoryComponent.vue";
import type { Account } from "@/utils";

const locale = useLocaleStore();

const accounts = ref<Account[]>([]);
const search = ref<string>("");
const showHistoryAccount = ref<Account | null>(null);

const filteredAccounts = computed<Array<Account>>(() => {
  return accounts.value.filter((account) => {
    if (search.value === "") return true;

    return (
      account.name?.toLowerCase().includes(search.value.toLowerCase()) ?? false
    );
  });
});

const showHistory = (account: Account) => {
  showHistoryAccount.value = account;
};

EventBus.on("phone:closeHistory", function () {
  showHistoryAccount.value = null;
});

const overallAccountsSum = computed<number>(() => {
  return accounts.value.reduce((acc, curr) => {
    return acc + curr.balance;
  }, 0);
});

const fetchAccounts = async () => {
  // @ts-ignore
  fetch(`https://fd_banking/fetchAccounts`, {
    method: "POST",
  });
};

EventBus.on("bank:setAccounts", function (data: any) {
  accounts.value =
    data.accounts.sort((a: any) => {
      if (a.type === "personal") return -1;

      return 0;
    }) ?? [];
});

onMounted(() => {
  fetchAccounts();
});
</script>
<template>
  <div
    class="w-full flex flex-col flex-1 overflow-hidden bg-[#25262b] items-center"
  >
    <div class="w-full h-[5vh]"></div>
    <div class="relative flex flex-col flex-1 overflow-hidden w-full">
      <Transition name="slide-fade" mode="out-in">
        <AccountHistoryComponent
          :account="showHistoryAccount"
          v-if="showHistoryAccount"
        />
      </Transition>
      <div class="flex flex-col px-7 py-5">
        <span class="font-bold text-gray-200 text-4xl">{{
          overallAccountsSum.toLocaleString(locale.get("currency_language"), {
            style: "currency",
            currency: locale.get("currency"),
          })
        }}</span>
        <span class="text-gray-400 text-base">
          {{ locale.get("total_account_balance") }}
        </span>
      </div>
      <div
        class="relative flex flex-col flex-1 w-full bg-[#2c2e33] rounded-t-3xl p-3 overflow-y-auto overflow-x-hidden gap-3 pb-32"
      >
        <div
          class="flex flex-col rounded-2xl overflow-hidden flex-shrink-0 transform hover:-translate-y-1 transition duration-350 ease-linear"
          v-for="(account, index) in filteredAccounts"
          :key="index"
          @click.prevent="showHistory(account)"
        >
          <div
            class="flex flex-col justify-between p-3 gap-10 bg-[#e5ede8] text-gray-900"
          >
            <div class="flex flex-col justify-between start">
              <span class="block font-semibold truncate text-lg">{{
                account.type === "personal"
                  ? locale.get("personal_account_title")
                  : account.name ?? locale.get("unknown")
              }}</span>
              <span class="block font-normal truncate text-base">
                {{ locale.get("type") }}:
                {{ locale.get(account.type) }}
                <span class="text-red-400 ml-2">
                  {{ account.is_frozen ? locale.get("frozen") : "" }}
                </span>
              </span>
            </div>
            <div class="flex justify-end items-center">
              <div class="flex justify-end gap-1 text-lg">
                <span>{{ locale.get("iban") }}:</span>
                <span class="font-bold tracking-wide">{{ account.iban }}</span>
              </div>
            </div>
          </div>
          <div
            class="flex justify-between items-center px-3 py-2 bg-[#85b899] text-gray-900"
          >
            <div class="text-lg">
              {{ locale.get("balance") }}
            </div>
            <div class="font-semibold text-lg">
              {{
                account.balance.toLocaleString(
                  locale.get("currency_language"),
                  {
                    style: "currency",
                    currency: locale.get("currency"),
                  },
                )
              }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
