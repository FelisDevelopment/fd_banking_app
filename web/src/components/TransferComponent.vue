<script setup lang="ts">
import { ref } from "vue";
import { z as zod } from "zod";
import { useField, useForm } from "vee-validate";
import { toFormValidator } from "@vee-validate/zod";
import { type Account, fetched } from "@/utils";
import { useLocaleStore } from "@/stores/locale";

const locale = useLocaleStore();

const props = defineProps<{
  account: Account;
}>();

const emit = defineEmits<{
  (e: "closeModal"): void;
}>();

const isDoingAction = ref<boolean>(false);
const responseError = ref<string>("");

const closeModal = () => {
  if (!isDoingAction.value) {
    emit("closeModal");
    responseError.value = "";
  }
};

const AccountNumberSchema = zod.object({
  account_number: zod.coerce
    .number({
      invalid_type_error: locale.get("account_number_invalid_type"),
      required_error: locale.get("account_number_is_required"),
    })
    .refine(
      (value) => Number.isInteger(value),
      locale.get("account_number_invalid_type"),
    ),
});

const PlayerIdSchema = zod.object({
  player_id: zod.coerce
    .number({
      invalid_type_error: locale.get("player_id_invalid_type"),
      required_error: locale.get("player_id_is_required"),
    })
    .refine(
      (value) => Number.isInteger(value),
      locale.get("player_id_invalid_type"),
    ),
});

const validationSchema = toFormValidator(
  zod
    .object({
      amount: zod
        .number({
          invalid_type_error: locale.get("amount_must_be_a_number"),
          required_error: locale.get("amount_is_required"),
        })
        .min(1, locale.get("amount_must_be_greater_than_0"))
        .max(1000000000, locale.get("amount_must_be_less_than_1000000000"))
        .refine(
          (value) => Number.isInteger(value),
          locale.get("amount_must_be_integer"),
        )
        .refine(
          (value) => value <= props.account.balance!,
          locale.get("there_is_not_enough_money_in_account"),
        ),
      description: zod
        .string({
          invalid_type_error: locale.get("description_must_be_a_string"),
          required_error: locale.get("description_is_required"),
        })
        .min(3, locale.get("description_must_be_at_least_3_characters_long"))
        .refine(
          (value) => /[a-zA-Z0-9\s]/.test(value),
          locale.get("only_letters_and_numbers_allowed"),
        ),
    })
    .merge(AccountNumberSchema.partial())
    .merge(PlayerIdSchema.partial())
    .superRefine((data, ctx) => {
      if (data.account_number && data.player_id) {
        ctx.addIssue({
          code: zod.ZodIssueCode.custom,
          path: ["account_number"],
          message: locale.get(
            "fill_in_only_one_field_account_number_or_player_id",
          ),
        });
      } else if (data.account_number) {
        const result = AccountNumberSchema.safeParse(data);
        if (!result.success) {
          result.error.errors.forEach((issue) => ctx.addIssue(issue));
        }
      } else if (data.player_id) {
        const result = PlayerIdSchema.safeParse(data);
        if (!result.success) {
          result.error.errors.forEach((issue) => ctx.addIssue(issue));
        }
      } else {
        ctx.addIssue({
          code: zod.ZodIssueCode.custom,
          path: ["account_number"],
          message: locale.get("account_number_or_player_id_is_required"),
        });
      }
    }),
);

const { handleSubmit } = useForm({
  validationSchema,
});

const { value: accountNumber, errorMessage: accountNumberError } =
  useField("account_number");
const { value: playerId, errorMessage: playerIdError } = useField("player_id");
const { value: amount, errorMessage: amountError } = useField("amount");
const { value: description, errorMessage: descriptionError } =
  useField("description");

const transferHandle = handleSubmit(async (values) => {
  if (!isDoingAction.value) {
    responseError.value = "";
    isDoingAction.value = true;
    try {
      const response = await fetched(`https://fd_banking/transferMoney`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          amount: values.amount,
          reason: values.description,
          id: props.account.id,
          account_number: values.account_number,
          player_id: values.player_id,
        }),
      });
      const data = await response.json();
      isDoingAction.value = false;
      if (!data) {
        responseError.value = locale.get("transfer_failed_please_try_again");
        return;
      }

      closeModal();
    } catch (e) {
      responseError.value = locale.get("transfer_failed_please_try_again");
      isDoingAction.value = false;
    }
  }
});
</script>
<template>
  <div
    class="absolute top-0 right-0 w-full h-full flex flex-col flex-1 bg-[#25262b] z-50 overflow-hidden flex-grow-0"
  >
    <div class="flex justify-between py-4 px-3">
      <h1 class="font-bold text-gray-200 text-3xl">
        {{ locale.get("transfer_title") }}
      </h1>
      <button
        type="button"
        class="relative inline-flex items-center rounded-md bg-transparent px-3 py-2 text-sm font-semibold text-gray-400 ring-1 ring-inset ring-[#373A40] hover:bg-[#373A40] hover:text-white focus:z-10"
        @click.prevent="closeModal()"
      >
        <i class="fa-solid fa-xmark"></i>
        <ToolTip :text="locale.get('close_button_tooltip')" />
      </button>
    </div>
    <div class="flex justify-between p-3 gap-3">
      <div class="flex flex-col">
        <span class="text-gray-400">
          {{ locale.get("transfer_description") }}
        </span>
      </div>
    </div>
    <div
      class="relative flex flex-col flex-1 w-full bg-[#2c2e33] rounded-t-3xl p-3 border-[#373A40] border-t overflow-y-auto overflow-x-hidden gap-3 pb-32"
    >
      <form class="flex flex-col gap-3" @submit.prevent="transferHandle()">
        <div class="flex flex-1 items-end gap-5">
          <div>
            <label
              for="account_number"
              class="block text-sm font-medium leading-6 text-gray-200"
            >
              {{ locale.get("account_number_label") }}
            </label>
            <div class="mt-2">
              <input
                type="number"
                v-model="accountNumber"
                name="account_number"
                id="account_number"
                class="block w-full rounded-md border-0 py-1.5 bg-transparent text-white shadow-sm ring-1 ring-inset ring-[#373A40] placeholder:text-gray-400 focus:ring-1 focus:ring-inset focus:ring-gray-400"
                placeholder="1001"
              />
            </div>
          </div>
          <p class="text-gray-500 text-sm mb-3">
            {{ locale.get("or_label") }}
          </p>
          <div>
            <label
              for="player_id"
              class="block text-sm font-medium leading-6 text-gray-200"
            >
              {{ locale.get("player_id_label") }}
            </label>
            <div class="mt-2">
              <input
                type="number"
                v-model="playerId"
                name="player_id"
                id="player_id"
                class="block w-full rounded-md border-0 py-1.5 bg-transparent text-white shadow-sm ring-1 ring-inset ring-[#373A40] placeholder:text-gray-400 focus:ring-1 focus:ring-inset focus:ring-gray-400"
                placeholder="1001"
              />
            </div>
          </div>
        </div>
        <div class="flex items-start justify-between gap-10">
          <p class="mt-1 text-sm text-red-400">
            {{ accountNumberError }}
          </p>
          <p class="mt-1 text-sm text-red-400">
            {{ playerIdError }}
          </p>
        </div>
        <div>
          <label
            for="amount"
            class="block text-sm font-medium leading-6 text-gray-200"
          >
            {{ locale.get("amount_label") }}
          </label>
          <div class="mt-2">
            <input
              v-model="amount"
              type="number"
              name="amount"
              id="amount"
              class="block w-full rounded-md border-0 py-1.5 bg-transparent text-white shadow-sm ring-1 ring-inset ring-[#373A40] placeholder:text-gray-400 focus:ring-1 focus:ring-inset focus:ring-gray-400"
              placeholder="200"
            />
          </div>
          <p class="mt-1 text-sm text-red-400" v-if="amountError">
            {{ amountError }}
          </p>
          <p class="mt-2 text-sm text-gray-500">
            {{ locale.get("in_account_currently_there_is") }}
            <span class="font-semibold text-green-600">{{
              account.balance
                ? account.balance.toLocaleString(
                    locale.get("currency_language"),
                    {
                      style: "currency",
                      currency: locale.get("currency"),
                    },
                  )
                : locale.get("no_funds")
            }}</span>
          </p>
        </div>
        <div>
          <label
            for="description"
            class="block text-sm font-medium leading-6 text-gray-200"
          >
            {{ locale.get("description_label") }}
          </label>
          <div class="mt-2">
            <input
              v-model="description"
              type="text"
              name="description"
              id="description"
              class="block w-full rounded-md border-0 py-1.5 bg-transparent text-white shadow-sm ring-1 ring-inset ring-[#373A40] placeholder:text-gray-400 focus:ring-1 focus:ring-inset focus:ring-gray-400"
              :placeholder="locale.get('transfer_description_placeholder')"
            />
          </div>
          <p class="mt-1 text-sm text-red-400" v-if="descriptionError">
            {{ descriptionError }}
          </p>
        </div>
        <div class="relative">
          <div class="absolute inset-0 flex items-center" aria-hidden="true">
            <div class="w-full border-t border-[#373A40]" />
          </div>
        </div>
        <div>
          <p class="mt-1 text-sm text-red-400" v-if="responseError">
            {{ responseError }}
          </p>
          <button
            type="submit"
            :class="[
              ...[
                'bg-[#85b899]',
                'hover:bg-[#e5ede8] hover:text-gray-900',
                'text-white',
              ],
              isDoingAction ? 'btn-loading' : '',
            ]"
            :disabled="isDoingAction"
            class="flex w-full justify-center rounded-md py-2 px-3 text-sm font-semibold shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
          >
            {{ locale.get("transfer_confirm_button") }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
