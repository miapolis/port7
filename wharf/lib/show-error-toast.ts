import { useErrorToastStore } from "@port7/modules/errors/use-error-toast-store";

export const showErrorToast = (message: string) => {
  useErrorToastStore.getState().showToast({ message: message });
};
