import React from "react";
import { WebSocketContext } from "../modules/ws/ws-provider";
import {
  useRoomChatStore,
  createSystemMessage,
} from "../modules/room/use-room-chat-store";
import { useRoomStore } from "@port7/modules/room/use-room-store";

export const useMainWsHandler = () => {
  const { conn } = React.useContext(WebSocketContext);

  React.useEffect(() => {
    if (!conn) return;

    const unsubs = [
      /////////////////////////////////////////////////////////////////////////
      ///// - PEER FUNCTIONS - ////////////////////////////////////////////////
      /////////////////////////////////////////////////////////////////////////
      conn.addListener("peer_join", ({ data }: any) => {
        useRoomStore.getState().addPeer(data.id, data.nickname, data.roles);
        useRoomChatStore
          .getState()
          .addMessage(createSystemMessage(`${data.nickname} joined`));
      }),
      conn.addListener("peer_leave", ({ data }: any) => {
        const nickname = useRoomStore.getState().peers.get(data.id)?.nickname;
        useRoomChatStore
          .getState()
          .addMessage(createSystemMessage(`${nickname} left`));
        useRoomStore.getState().disconnectPeer(data.id);
      }),
      conn.addListener("remove_peer", ({ data }: any) => {
        const peer = useRoomStore.getState().peers.get(data.id);
        // Peer is to be immediately removed, a message in chat is needed
        if (peer && !peer.isDisconnected) {
          let ending = "left";
          switch (data.action) {
            case "kick":
              ending = "was kicked";
              break;
          }

          useRoomChatStore
            .getState()
            .addMessage(createSystemMessage(`${peer.nickname} ${ending}`));
        }
        useRoomStore.getState().removePeer(data.id);
      }),
      conn.addListener("new_leader", ({ data }: any) => {
        let peer = useRoomStore.getState().peers.get(data.id);
        if (!peer) return;

        peer.roles = data.roles;
        useRoomStore.getState().updatePeer(peer);

        let message = `${peer.nickname} is now leader`;
        if (peer.id === useRoomStore.getState().myPeerId) {
          message = "You are now leader";
        }

        useRoomChatStore.getState().addMessage(createSystemMessage(message));
      }),
      /////////////////////////////////////////////////////////////////////////
      ///// - CHAT FUNCTIONS - ////////////////////////////////////////////////
      /////////////////////////////////////////////////////////////////////////
      conn.addListener("chat:send", ({ data }: any) => {
        useRoomChatStore.getState().addMessage(data);
      }),
      /////////////////////////////////////////////////////////////////////////
      ///// - GENERAL FUNCTIONS - /////////////////////////////////////////////
      /////////////////////////////////////////////////////////////////////////
      conn.addListener("kicked", ({ data }: any) => {
        useRoomStore.getState().setDisconnected(data.type);
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
