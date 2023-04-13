<script setup lang="ts">
import { useLocaleStore } from "@/stores/locale";
import { fetched } from "@/utils";
import { DateTime } from "luxon";
import { computed, ref } from "vue";
// @ts-ignore
import InfiniteLoading from "v3-infinite-loading";
import "v3-infinite-loading/lib/style.css";

const locale = useLocaleStore();

interface Invoice {
  id: number;
  issued_by: string;
  status: number;
  description: string;
  due_on: string;
  created_at: string;
  updated_at: string;
  can_be_declined: boolean;
  amount: number;
}

const unpaidInvoices = ref<Invoice[]>([]);
const search = ref<string>("");
const page = ref<number>(1);
const isProcessing = ref<boolean>(false);
const timeZone = ref<string>(Intl.DateTimeFormat().resolvedOptions().timeZone);

const filteredUnpaidInvoices = computed<Array<Invoice>>(() => {
  return unpaidInvoices.value.filter((invoice) => {
    if (search.value === "") return true;

    return (
      (invoice.description
        ?.toLowerCase()
        .includes(search.value.toLowerCase()) ||
        invoice.issued_by
          ?.toLowerCase()
          .includes(search.value.toLowerCase())) ??
      false
    );
  });
});

const unpaidInvoicesLoading = async ($state: any) => {
  try {
    const response = await fetched(`https://fd_banking/unpaidInvoices`, {
      method: "POST",
      body: JSON.stringify({
        page: page.value,
        limit: 20,
      }),
    });

    const json: Array<Invoice> = await response.json();

    if (json.length < 20) {
      unpaidInvoices.value!.push(...json);
      $state.complete();
    } else {
      unpaidInvoices.value!.push(...json);
      $state.loaded();
    }

    page.value++;
  } catch (error) {
    $state.error();
  }
};

const getProperDate = computed(() => (date: string) => {
  if (!date) return locale.get("no_due_date");

  return DateTime.fromISO(date, {
    zone: "UTC",
  })
    .setZone(timeZone.value)
    .toFormat("yyyy-MM-dd HH:mm");
});

const payInvoice = async (id: number) => {
  if (isProcessing.value) return;

  isProcessing.value = true;

  try {
    const response = await fetched(`https://fd_banking/payInvoice`, {
      method: "POST",
      body: JSON.stringify({
        id,
      }),
    });

    const data: boolean = await response.json();

    if (data) {
      const index = unpaidInvoices.value!.findIndex(
        (invoice) => invoice.id === id,
      );

      if (index !== -1) {
        unpaidInvoices.value!.splice(index, 1);
      }
    }

    isProcessing.value = false;
  } catch (error) {
    console.error(error);
    isProcessing.value = false;
  }
};

const declineInvoice = async (id: number) => {
  if (isProcessing.value) return;

  isProcessing.value = true;

  try {
    const response = await fetched(`https://fd_banking/declineInvoice`, {
      method: "POST",
      body: JSON.stringify({
        id,
      }),
    });

    const data: boolean = await response.json();

    if (data) {
      const index = unpaidInvoices.value!.findIndex(
        (invoice) => invoice.id === id,
      );

      if (index !== -1) {
        unpaidInvoices.value!.splice(index, 1);
      }
    }

    isProcessing.value = false;
  } catch (error) {
    console.error(error);
    isProcessing.value = false;
  }
};
</script>
<template>
  <div
    class="w-full flex flex-col flex-1 overflow-hidden bg-[#25262b] items-center"
  >
    <div class="w-full h-[5vh]"></div>
    <div class="flex flex-col flex-1 overflow-hidden w-full">
      <div class="flex justify-between py-4 px-3">
        <span class="font-bold text-gray-200 text-3xl">{{
          locale.get("invoices")
        }}</span>
        <input
          type="text"
          name="fd_banking_search"
          id="search"
          v-model="search"
          class="block w-1/3 rounded-md border-0 py-2 px-1 bg-transparent text-sm text-white shadow-sm ring-1 ring-inset ring-[#373A40] placeholder:text-gray-400 focus:border-[#373A40] focus:ring-1 font-normal"
          :placeholder="locale.get('search_label')"
        />
      </div>
      <div
        class="flex flex-col flex-1 justify-center items-center py-10 gap-5"
        v-if="unpaidInvoices.length < 1"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          data-name="Layer 1"
          width="647.63626"
          height="632.17383"
          viewBox="0 0 647.63626 632.17383"
          xmlns:xlink="http://www.w3.org/1999/xlink"
          class="h-60"
        >
          <path
            d="M687.3279,276.08691H512.81813a15.01828,15.01828,0,0,0-15,15v387.85l-2,.61005-42.81006,13.11a8.00676,8.00676,0,0,1-9.98974-5.31L315.678,271.39691a8.00313,8.00313,0,0,1,5.31006-9.99l65.97022-20.2,191.25-58.54,65.96972-20.2a7.98927,7.98927,0,0,1,9.99024,5.3l32.5498,106.32Z"
            transform="translate(-276.18187 -133.91309)"
            fill="#f2f2f2"
          />
          <path
            d="M725.408,274.08691l-39.23-128.14a16.99368,16.99368,0,0,0-21.23-11.28l-92.75,28.39L380.95827,221.60693l-92.75,28.4a17.0152,17.0152,0,0,0-11.28028,21.23l134.08008,437.93a17.02661,17.02661,0,0,0,16.26026,12.03,16.78926,16.78926,0,0,0,4.96972-.75l63.58008-19.46,2-.62v-2.09l-2,.61-64.16992,19.65a15.01489,15.01489,0,0,1-18.73-9.95l-134.06983-437.94a14.97935,14.97935,0,0,1,9.94971-18.73l92.75-28.4,191.24024-58.54,92.75-28.4a15.15551,15.15551,0,0,1,4.40966-.66,15.01461,15.01461,0,0,1,14.32032,10.61l39.0498,127.56.62012,2h2.08008Z"
            transform="translate(-276.18187 -133.91309)"
            fill="#3f3d56"
          />
          <path
            d="M398.86279,261.73389a9.0157,9.0157,0,0,1-8.61133-6.3667l-12.88037-42.07178a8.99884,8.99884,0,0,1,5.9712-11.24023l175.939-53.86377a9.00867,9.00867,0,0,1,11.24072,5.9707l12.88037,42.07227a9.01029,9.01029,0,0,1-5.9707,11.24072L401.49219,261.33887A8.976,8.976,0,0,1,398.86279,261.73389Z"
            transform="translate(-276.18187 -133.91309)"
            fill="#d1d5db"
          />
          <circle cx="190.15351" cy="24.95465" r="20" fill="#d1d5db" />
          <circle cx="190.15351" cy="24.95465" r="12.66462" fill="#fff" />
          <path
            d="M878.81836,716.08691h-338a8.50981,8.50981,0,0,1-8.5-8.5v-405a8.50951,8.50951,0,0,1,8.5-8.5h338a8.50982,8.50982,0,0,1,8.5,8.5v405A8.51013,8.51013,0,0,1,878.81836,716.08691Z"
            transform="translate(-276.18187 -133.91309)"
            fill="#e6e6e6"
          />
          <path
            d="M723.31813,274.08691h-210.5a17.02411,17.02411,0,0,0-17,17v407.8l2-.61v-407.19a15.01828,15.01828,0,0,1,15-15H723.93825Zm183.5,0h-394a17.02411,17.02411,0,0,0-17,17v458a17.0241,17.0241,0,0,0,17,17h394a17.0241,17.0241,0,0,0,17-17v-458A17.02411,17.02411,0,0,0,906.81813,274.08691Zm15,475a15.01828,15.01828,0,0,1-15,15h-394a15.01828,15.01828,0,0,1-15-15v-458a15.01828,15.01828,0,0,1,15-15h394a15.01828,15.01828,0,0,1,15,15Z"
            transform="translate(-276.18187 -133.91309)"
            fill="#3f3d56"
          />
          <path
            d="M801.81836,318.08691h-184a9.01015,9.01015,0,0,1-9-9v-44a9.01016,9.01016,0,0,1,9-9h184a9.01016,9.01016,0,0,1,9,9v44A9.01015,9.01015,0,0,1,801.81836,318.08691Z"
            transform="translate(-276.18187 -133.91309)"
            fill="#d1d5db"
          />
          <circle cx="433.63626" cy="105.17383" r="20" fill="#d1d5db" />
          <circle cx="433.63626" cy="105.17383" r="12.18187" fill="#fff" />
        </svg>
        <span class="text-2xl font-semibold text-gray-300">{{
          locale.get("no_unpaid_invoices")
        }}</span>
      </div>
      <div
        v-else
        class="overflow-y-auto overflow-x-hidden flex flex-col flex-1 w-full"
      >
        <ul role="list" class="divide-y divide-gray-500">
          <li v-for="invoice in filteredUnpaidInvoices" :key="invoice.id">
            <a href="#" class="block hover:bg-[#373A40]">
              <div class="px-4 py-4 sm:px-6">
                <div class="flex items-start justify-between">
                  <div class="flex flex-col">
                    <p class="truncate font-medium text-xs text-gray-500">
                      {{ locale.get("invoice_description") }}
                    </p>
                    <p class="truncate font-medium text-gray-200">
                      {{ invoice.description }}
                    </p>
                  </div>
                  <div
                    class="ml-2 flex flex-col gap-1 flex-shrink-0 font-semibold text-gray-200"
                  >
                    {{
                      invoice.amount
                        ? invoice.amount.toLocaleString(
                            locale.get("currency_language"),
                            {
                              style: "currency",
                              currency: locale.get("currency"),
                            },
                          )
                        : locale.get("unknown")
                    }}
                  </div>
                </div>
                <div class="mt-3">
                  <div class="">
                    <p class="flex items-center text-gray-400">
                      {{ invoice.issued_by }}
                    </p>
                    <p class="mt-2 flex items-center text-gray-400">
                      <span class="font-medium text-gray-200">
                        {{ locale.get("invoice_due_date") }} </span
                      >:
                      {{ getProperDate(invoice.due_on) }}
                    </p>
                  </div>
                  <div class="mt-2 flex items-center text-gray-400">
                    <p>
                      <span class="font-medium text-gray-200">
                        {{ locale.get("invoice_issued_on") }} </span
                      >:
                      {{ getProperDate(invoice.created_at) }}
                    </p>
                  </div>
                </div>
                <div class="flex gap-3 py-1">
                  <button
                    v-if="invoice.status === 1"
                    :class="[
                      'bg-[#85b899]',
                      'hover:bg-[#e5ede8] hover:text-gray-900',
                      'text-white',
                    ]"
                    :disabled="isProcessing"
                    @click.prevent="payInvoice(invoice.id)"
                    class="relative inline-flex w-full items-center justify-center rounded-md px-3 py-2 text-sm font-semibold focus:z-10 disabled:bg-gray-400"
                  >
                    {{ locale.get("pay_button") }}
                  </button>
                  <button
                    v-if="invoice.status === 1 && invoice.can_be_declined"
                    :class="[
                      'bg-[#85b899]',
                      'hover:bg-[#e5ede8] hover:text-gray-900',
                      'text-white',
                    ]"
                    :disabled="isProcessing"
                    @click.prevent="declineInvoice(invoice.id)"
                    class="relative inline-flex w-full items-center justify-center rounded-md px-3 py-2 text-sm font-semibold focus:z-10 disabled:bg-gray-400"
                  >
                    {{ locale.get("decline_button") }}
                  </button>
                </div>
              </div>
            </a>
          </li>
        </ul>
      </div>
      <InfiniteLoading
        class="flex items-center justify-center text-gray-500"
        @infinite="unpaidInvoicesLoading"
        :slots="{
          // eslint-disable-next-line no-irregular-whitespace
          complete: ' ',
          error: locale.get('error_occurred'),
        }"
      />
    </div>
  </div>
</template>
