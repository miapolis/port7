import React from "react";
import { Room } from "@port7/dock/lib/interfaces";
import { setPreferredNickname, useUserStore } from "@port7/user";
import { useConn } from "@port7/hooks/use-conn";
import { useAuthStore } from "../auth/use-auth-store";

export interface WaitForSetUserProps {
  room: Room;
}

export const WaitForSetUser: React.FC<WaitForSetUserProps> = ({
  room,
  children,
}) => {
  const conn = useConn();
  const user = useUserStore();
  const auth = useAuthStore();
  const landingNickname = user.user?.nickname || "";
  const [isReady, setIsReady] = React.useState(false);
  const [nickname, setNickname] = React.useState(landingNickname);

  const playClicked = async () => {
    if (nickname !== landingNickname) {
      setPreferredNickname(nickname);
      user.setUser(nickname, true);
    }
    await conn?.sendCall("auth:request", { nickname: nickname });
    useUserStore.getState().setUser(nickname, true);
    auth.setIsAuthenticated(true);
    setIsReady(true);
  };

  if (!user.user?.isPreferredNickname && !isReady) {
    return (
      <div className="m-auto w-96 bg-primary-600 p-6 rounded-lg flex flex-col shadow-lg">
        <div className="text-2xl text-primary-100 mb-4">
          Joining <b>{`${room.name}`}</b>
        </div>
        <div className="text-md text-primary-200 mb-2">Nickname</div>
        <input
          className="h-10 px-3 mb-4 w-full rounded-md focus:outline-none bg-transparent text-primary-100 ring-2 ring-primary-300 focus:ring-accent transition"
          value={nickname}
          placeholder="Nickname"
          onChange={(e) => setNickname(e.target.value)}
        />
        <button
          onClick={() => playClicked()}
          className="bg-accent text-primary-100 w-full p-2 font-bold rounded-md shadow-md hover:bg-accent-hover transition"
        >
          PLAY
        </button>
      </div>
    );
  }

  return <>{children}</>;
};
