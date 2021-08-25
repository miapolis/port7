import React from "react";
import { useConn } from "@port7/hooks/use-conn";
import { GetProfilesResponse, ManagedPeer } from "@port7/dock/lib";
import SettingsIcon from "@material-ui/icons/Settings";
import { useRoomStore } from "./use-room-store";
import { myIntents } from "@port7/lib/authority";
import { useManagePeerStore } from "./use-manage-peer-store";
import { usePeerModalStore } from "./use-peer-modal-store";
import { useProfilesStore } from "./use-profiles-store";

export const PeerList: React.FC = () => {
  const conn = useConn();
  const room = useRoomStore();
  const profileStore = useProfilesStore();

  React.useEffect(() => {
    getProfiles(conn);
  }, []);

  return (
    <div>
      {profileStore.profiles.map((p) => (
        <PeerItem peer={p} isMe={p.id === room.myPeerId} />
      ))}
    </div>
  );
};

interface PeerItemProps {
  peer: ManagedPeer;
  isMe: boolean;
}

const PeerItem = ({ peer, isMe }: PeerItemProps) => {
  const [manageUserIconHover, setManagerUserIconHover] = React.useState(false);
  const [canManage, setCanManage] = React.useState(
    !isMe && myIntents().includes("MANAGE PEERS")
  );

  return (
    <div
      className="bg-primary-600 rounded-md w-full p-4 mb-4 flex items-center relative transition"
      key={peer.id}
    >
      <div className="flex flex-col ">
        <div className="flex">
          <div className="text-primary-100">{peer.nickname}</div>
          {peer.roles.length > 0 ? (
            <>
              <span className="text-primary-300 mx-1">•</span>
              <span className="text-primary-100 font-bold">
                {elementsToString(peer.roles)}
              </span>
            </>
          ) : null}
        </div>
        <div className="text-primary-200">{`Guest ${peer.id}`}</div>
      </div>
      <div
        className="absolute right-4 w-10 h-10 flex items-center justify-center cursor-pointer"
        onMouseEnter={() => setManagerUserIconHover(true)}
        onMouseLeave={() => setManagerUserIconHover(false)}
      >
        {canManage ? (
          <SettingsIcon
            style={{
              color: manageUserIconHover
                ? "var(--color-primary-100)"
                : "var(--color-primary-200)",
              width: 30,
              height: 30,
              transition: "transform 0.2s, color 0.2s",
              transform: manageUserIconHover ? "rotate(20deg)" : "",
            }}
            onClick={() => {
              useManagePeerStore.getState().setPeer(peer);
              usePeerModalStore.getState().setOpen(true);
            }}
          />
        ) : null}
      </div>
    </div>
  );
};

export const getProfiles = async (conn: any) => {
  const response: GetProfilesResponse = (
    (await conn?.sendCall("room:get_profiles", {})) as any
  ).data;
  useProfilesStore.getState().setProfiles(response.profiles);
};

const elementsToString = (arr: any[]): string => {
  let str = "";
  for (let i = 0; i < arr.length; i++) {
    if (i === 0) str += arr[i];
    else str += `, ${arr[i]}`;
  }

  return str;
};
