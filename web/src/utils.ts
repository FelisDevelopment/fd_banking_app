export const fetched = async (
  url: string,
  opts: Record<string, any> = {},
  timeout: number = 5000,
) => {
  // Create the AbortController instance, get AbortSignal
  const abortController = new AbortController();
  const { signal } = abortController;

  // Make the fetch request
  const _fetchPromise = fetch(url, {
    ...opts,
    signal,
  });

  // Start the timer
  const timer = setTimeout(() => abortController.abort(), timeout);

  // Await the fetch with a catch in case it's aborted which signals an error
  try {
    const result = await _fetchPromise;
    clearTimeout(timer);
    return result;
  } catch (e) {
    clearTimeout(timer);
    throw e;
  }
};

export type Account = {
  id: number;
  name: string | null;
  type: string;
  iban: string;
  balance: number;
  can_deposit?: number;
  can_withdraw?: number;
  can_transfer?: number;
  can_export?: number;
  can_control_members?: number;
  is_owner?: number;
  is_frozen?: number;
  is_society?: number;
};

export interface Transaction {
  id: number;
  account_id: number;
  action: string;
  done_by: string;
  amount: number;
  from_account: number;
  to_account: number;
  description: string;
  created_at: string;
}
