import React from "react";
import { WebSocketContext } from "../ws/ws-provider";
import { setPreferredNickname, useUserStore } from "@port7/user";
import { getUserToken } from "@port7/lib/user-token";
import { useRoomStore } from "../room/use-room-store";

export const WaitForWsAndAuth: React.FC = ({ children }) => {
  const { conn } = React.useContext(WebSocketContext);
  const user = useUserStore();
  const room = useRoomStore().room;

  const landingNickname = user.user?.nickname || "";
  const [nickname, setNickname] = React.useState(landingNickname);
  const [waiting, setWaiting] = React.useState(true);
  const [didAuth, setDidAuth] = React.useState(false);

  React.useEffect(() => {
    setTimeout(() => setWaiting(false), 500);
  }, []);

  React.useEffect(() => {
    const func = async () => {
      // Authentication will be done later when they set their own nickname
      if (!user.user?.isPreferredNickname) return;
      await doAuth();
    };
    func();
  }, [conn, user]);

  const playClicked = async () => {
    await doAuth();

    if (nickname !== landingNickname) {
      setPreferredNickname(nickname);
      user.setUser(nickname, true);
    }
  };

  const doAuth = async () => {
    if (!conn || !user.user) return;
    if (didAuth) return;

    await conn.sendCall("auth:request", {
      nickname: nickname,
      userToken: getUserToken(),
    });
    setDidAuth(true);
  };

  if (!conn || waiting) {
    return (
      <div className="flex text-2xl text-primary-100 m-auto">Loading...</div>
    );
  }

  if (!user.user?.isPreferredNickname && !didAuth) {
    return (
      <div className="m-auto w-96 bg-primary-600 p-6 rounded-lg flex flex-col shadow-lg">
        <div className="text-2xl text-primary-100 mb-4">
          Joining <b>{`${room?.name}`}</b>
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

  if (user.user?.isPreferredNickname && !didAuth) {
    return <div className="text-primary-100">Hello</div>;
  }

  return <>{children}</>;
};
