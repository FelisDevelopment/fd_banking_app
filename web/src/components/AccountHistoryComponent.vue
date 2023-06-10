<script setup lang="ts">
import { EventBus } from "@/event-bus";
import { useLocaleStore } from "@/stores/locale";
import { fetched, type Account, type Transaction } from "@/utils";
import { DateTime } from "luxon";
import { computed, onMounted, ref } from "vue";
// @ts-ignore
import InfiniteLoading from "v3-infinite-loading";
import "v3-infinite-loading/lib/style.css";
import TransferComponent from "./TransferComponent.vue";

const locale = useLocaleStore();
const props = defineProps<{
  account: Account;
}>();

const accountData = ref<Account | null>(null);
const transactions = ref<Transaction[] | null>([]);
const page = ref<number>(1);
const isFetching = ref<boolean>(false);
const timeZone = ref<string>(Intl.DateTimeFormat().resolvedOptions().timeZone);
const transferOpen = ref<boolean>(false);

const closeHistory = () => {
  EventBus.emit("phone:closeHistory", {});
};

const fetchAccount = async (id: number, override?: boolean) => {
  if (!isFetching.value && (accountData.value?.id !== id || override)) {
    isFetching.value = true;

    // Reset data
    accountData.value = null;
    transactions.value = [];
    page.value = 1;

    try {
      const response = await fetched(`https://fd_banking/loadAccount`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          id,
        }),
      });

      const data = await response.json();

      isFetching.value = false;

      if (!data) {
        return;
      }
    } catch (e) {
      isFetching.value = false;
    }
  }
};

const getRelativeDate = (date: string) => {
  return DateTime.fromISO(date, {
    zone: "UTC",
  })
    .setZone(timeZone.value)
    .toRelative();
};

const isPersonal = computed<boolean>(() => {
  if (!accountData.value) return false;

  return accountData.value.type === "personal";
});

const isOwner = computed<boolean>(() => {
  if (!accountData.value) return false;

  return accountData.value.is_owner == 1;
});

const isFrozen = computed<boolean>(() => {
  if (!accountData.value) return false;

  return accountData.value.is_frozen == 1;
});

const canTransfer = computed<boolean>(() => {
  if (!accountData.value) return false;

  if (isFrozen.value) return false;

  if (isPersonal.value) return true;

  if (isOwner.value) return true;

  if (accountData.value.can_transfer == 1) return true;

  return false;
});

EventBus.on("bank:setAccount", (data: any) => {
  accountData.value = data.account;
  transactions.value = [];
});

const transactionsLoading = async ($state: any) => {
  try {
    const response = await fetched(`https://fd_banking/transactions`, {
      method: "POST",
      body: JSON.stringify({
        page: page.value,
        limit: 20,
        id: props.account.id,
      }),
    });

    const json: Array<Transaction> = await response.json();

    if (json.length < 20) {
      transactions.value!.push(...json);
      $state.complete();
    } else {
      transactions.value!.push(...json);
      $state.loaded();
    }

    page.value++;
  } catch (error) {
    $state.error();
  }
};

const formatTransactionTitle = (transaction: Transaction) => {
  if (transaction.action === "deposit") {
    return locale.get("deposited_to_account_title");
  }

  if (transaction.action === "withdraw") {
    return locale.get("withdrawn_from_account_title");
  }

  if (transaction.action === "transferin") {
    return locale
      .get("transfered_to_account_title")
      .format(
        [0, 1].includes(transaction.from_account)
          ? locale.get("unknown_source")
          : transaction.from_account,
      );
  }

  if (transaction.action === "transferout") {
    return locale
      .get("transfered_from_account_title")
      .format(
        [0, 1].includes(transaction.to_account)
          ? locale.get("unknown_source")
          : transaction.to_account,
      );
  }

  if (transaction.action === "payment") {
    return locale
      .get("payment_for_invoice")
      .format(
        [0, 1].includes(transaction.to_account)
          ? locale.get("unknown_source")
          : transaction.to_account,
      );
  }

  return locale.get("unknown");
};

const transferMoney = async () => {
  transferOpen.value = true;
};

const closedTransfer = () => {
  transferOpen.value = false;

  fetchAccount(props.account.id, true);
};

onMounted(() => {
  fetchAccount(props.account.id, true);
});
</script>
<template>
  <div
    class="absolute top-0 right-0 w-full h-full flex flex-col flex-1 bg-[#25262b] z-50 overflow-hidden flex-grow-0"
  >
    <Transition name="slide-fade" mode="out-in">
      <TransferComponent
        :account="accountData!"
        v-if="transferOpen"
        @closeModal="closedTransfer()"
      />
    </Transition>

    <div class="flex justify-between py-4 px-3">
      <span class="font-bold text-gray-200 text-3xl">{{
        locale.get("transaction_history")
      }}</span>
      <button
        type="button"
        class="relative inline-flex items-center rounded-md bg-transparent px-3 py-2 text-sm font-semibold text-gray-400 ring-1 ring-inset ring-[#373A40] hover:bg-[#373A40] hover:text-white focus:z-10"
        @click.prevent="closeHistory()"
      >
        <i class="fa-solid fa-xmark"></i>
      </button>
    </div>
    <div class="flex justify-between p-3">
      <div class="flex flex-col">
        <span class="text-gray-400">
          {{
            account.type === "personal"
              ? locale.get("personal_account_title")
              : account.name ?? locale.get("unknown")
          }}
        </span>
        <span class="text-gray-400">{{
          accountData?.balance.toLocaleString(locale.get("currency_language"), {
            style: "currency",
            currency: locale.get("currency"),
          }) ?? "0"
        }}</span>
        <span class="text-gray-400">
          {{ locale.get("iban") }}:
          {{ account.iban }}
        </span>
      </div>
      <div class="">
        <button
          type="button"
          v-if="canTransfer"
          @click.prevent="transferMoney()"
          class="relative inline-flex items-center bg-transparent px-3 py-2 text-sm font-semibold text-gray-400 ring-1 ring-inset ring-[#373A40] hover:bg-[#373A40] hover:text-white focus:z-10 rounded-lg"
        >
          {{ locale.get("transfer") }}
        </button>
      </div>
    </div>
    <div
      class="relative flex flex-col flex-1 w-full bg-[#2c2e33] rounded-t-3xl p-3 border-[#373A40] border-t overflow-y-auto overflow-x-hidden gap-3 pb-32"
      v-if="accountData"
    >
      <ul role="list" class="space-y-2">
        <li v-for="transaction in transactions" :key="transaction.id">
          <div
            class="block space-y-2 border border-[#373A40] bg-[#212227] rounded-2xl"
          >
            <div class="p-5">
              <div class="flex items-center justify-between">
                <p class="truncate text-lg font-medium text-white">
                  {{ formatTransactionTitle(transaction) }}
                </p>
                <div class="ml-2 flex flex-shrink-0">
                  <p
                    class="inline-flex rounded-full px-2 text-xs font-semibold leading-5"
                    :class="['bg-[#85b899]', 'text-gray-700']"
                  >
                    {{
                      locale.get(`${transaction.action}_action`) ??
                      locale.get("unknown")
                    }}
                  </p>
                </div>
              </div>
              <div class="mt-2 flex justify-between">
                <div class="">
                  <p class="text-sm text-gray-400">
                    {{ locale.get("made_by") }}:
                    <span class="font-semibold">{{ transaction.done_by }}</span>
                  </p>
                  <p class="text-sm text-gray-400">
                    {{ getRelativeDate(transaction.created_at) }}
                  </p>
                </div>
                <div class="font-bold text-xl text-white">
                  {{
                    transaction.amount.toLocaleString(
                      locale.get("currency_language"),
                      {
                        style: "currency",
                        currency: locale.get("currency"),
                      },
                    )
                  }}
                </div>
              </div>
              <div
                class="w-full flex flex-col border-t border-gray-400 mt-2 pt-2"
              >
                <p class="text-gray-500 text-xs">
                  {{ locale.get("message") }}
                </p>
                <p class="text-gray-200">{{ transaction.description }}</p>
              </div>
            </div>
          </div>
        </li>
      </ul>
      <InfiniteLoading
        class="flex items-center justify-center text-gray-500"
        @infinite="transactionsLoading"
        :slots="{
          complete: locale.get('no_more_records'),
          error: locale.get('error_occurred'),
        }"
      />
    </div>
  </div>
</template>
