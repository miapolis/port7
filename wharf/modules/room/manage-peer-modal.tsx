import React from "react";
import { useConn } from "@port7/hooks/use-conn";
import { getProfiles } from "./peer-list";
import { useManagePeerStore } from "./use-manage-peer-store";
import { usePeerModalStore } from "./use-peer-modal-store";

export interface ManagePeerModalProps {
  open?: boolean;
  onClose?: () => void;
}

type ActionType = "kick" | "ban" | "promote mod" | "demote mod";

export const ManagePeerModal: React.FC<ManagePeerModalProps> = ({
  open = false,
  onClose,
}) => {
  const conn = useConn();
  const peer = useManagePeerStore().peer;

  if (!open || !peer) return null;

  const onAction = async (action: ActionType) => {
    switch (action) {
      case "kick":
        conn?.sendCast("room:kick", { id: peer.id });
        break;
    }
    usePeerModalStore.getState().setOpen(false);
    getProfiles(conn);
  };

  return (
    <div className="fixed w-full h-full z-10">
      <div className="flex w-full h-full items-center justify-center">
        <div className="flex flex-col w-96 p-8 bg-primary-600 rounded-lg shadow-lg z-10">
          <div className="mb-10">
            <div className="font-bold text-2xl text-primary-100">
              {peer.nickname}
            </div>
            <div className="text-primary-200 text-lg">{`${
              peer.authMethod === "port7" ? "GUEST" : peer.authMethod
            } ${peer.id}`}</div>
          </div>
          <div className="text-primary-100 text-lg mb-3">Actions</div>
          <button
            onClick={() => onAction("kick")}
            className="bg-accent mb-3 text-primary-100 p-2 font-bold rounded-md shadow-md hover:bg-accent-hover transition"
          >
            KICK
          </button>
          <button className="bg-ternary mb-3 text-primary-100 p-2 font-bold rounded-md shadow-md hover:bg-ternary-hover transition">
            BAN
          </button>
          <button className="bg-secondary text-primary-100 p-2 font-bold rounded-md shadow-md hover:bg-secondary-hover transition">
            PROMOTE TO MOD
          </button>
        </div>
        <div
          className="fixed w-full h-full bg-black bg-opacity-30"
          onClick={() => onClose?.()}
        />
      </div>
    </div>
  );
};
