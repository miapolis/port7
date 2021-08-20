import React from "react";
import { WebSocketContext } from "../modules/ws/ws-provider";
import { useRoomChatStore, createSystemMessage } from "../modules/room/use-room-chat-store";
import { useRoomStore } from "@port7/modules/room/use-room-store";

export const useMainWsHandler = () => {
  const { conn } = React.useContext(WebSocketContext);

  React.useEffect(() => {
    if (!conn) return;

    const unsubs = [
      conn.addListener("peer_join", ({data}: any) => {
        useRoomStore.getState().addPeer(data.id, data.nickname);
        useRoomChatStore.getState().addMessage(createSystemMessage(`${data.nickname} joined`));
      }),
      conn.addListener("peer_leave", ({data}: any) => {
        const nickname = useRoomStore.getState().room?.peers.find(x => x.id === data.id)?.nickname
        useRoomChatStore.getState().addMessage(createSystemMessage(`${nickname} left`));
        useRoomStore.getState().removePeer(data.id);
      }),
      conn.addListener("chat:send", ({ data }: any) => {
        useRoomChatStore.getState().addMessage(data)
      }),
    ];

    return () => {
      unsubs.forEach((u) => u());
    };
  }, [conn]);
};

export const MainWsHandlerProvider: React.FC = ({ children }) => {
  useMainWsHandler();
  return <>{children}</>;
};
