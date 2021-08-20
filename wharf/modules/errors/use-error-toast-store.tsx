import React from "react";
import create from "zustand";
import { v4 as uuidv4 } from "uuid";
import { ToastDurations } from "@port7/ui/error-toast";

type Toast = {
  id: string;
  button?: React.ReactNode;
  duration?: ToastDurations;
  message: string;
};

interface State {
  toasts: Toast[];
  hideToast: (id: string) => void;
  showToast: (t: Omit<Toast, "id">) => void;
}

export const useErrorToastStore = create<State>((set) => ({
  toasts: [] as Toast[],
  hideToast: (id: string) => {
    set((state) => ({
      toasts: state.toasts.filter((t) => t.id !== id),
    }));
  },
  showToast: (t: Omit<Toast, "id">) => {
    set((state) => {
      const currentRemovedToasts: Toast[] = state.toasts.filter(
        (x) => x.message !== t.message
      );
      return {
        toasts: [...currentRemovedToasts, { ...t, id: uuidv4() }],
      };
    });
  },
}));
