import create from "zustand";

interface ModalState {
  open: boolean;
  setOpen: (open: boolean) => void;
}

export const usePeerModalStore = create<ModalState>((set) => ({
  open: false,
  setOpen: (open: boolean) => {
    set((_state) => ({
      open: open,
    }));
  },
}));
