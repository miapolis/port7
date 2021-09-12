import React from "react";
import { PageComponent } from "@port7/types/page-component";
import { apiBaseUrl } from "@port7/lib/constants";
import { WaitForWsAndAuth } from "@port7/modules/auth/wait-for-ws-auth";
import { Room } from "@port7/dock";
import { RoomEnter } from "@port7/modules/room/room-enter";
import { useRoomStore } from "@port7/modules/room/use-room-store";
import { Header } from "@port7/modules/room/header";
import { MainLayout } from "@port7/modules/room/main-layout";
import { ChatPanel } from "@port7/modules/room/chat-panel";
import { ManagePeerModal } from "@port7/modules/room/manage-peer-modal";
import { usePeerModalStore } from "@port7/modules/room/use-peer-modal-store";
import { KEY_CHAT_OPEN } from "@port7/lib/local-storage";

interface RoomPageProps {
  room?: Room;
}

const RoomPage: PageComponent<RoomPageProps> = ({ room }) => {
  const roomStore = useRoomStore();
  const peerModalStore = usePeerModalStore();

  const [chatOpen, setChatOpen] = React.useState(() => {
    const value = localStorage.getItem(KEY_CHAT_OPEN);
    return value == undefined || value === "true";
  });

  React.useEffect(() => {
    roomStore.setRoom(room);
    roomStore.setPeers([]);
  }, [room]);

  return (
    <>
      {room ? (
        <WaitForWsAndAuth>
          <RoomEnter room={room}>
            <div className="w-full h-full flex flex-col">
              <Header
                chatOpen={chatOpen}
                onChatOpenToggel={() => {
                  setChatOpen(!chatOpen);
                  localStorage.setItem(KEY_CHAT_OPEN, (!chatOpen).toString());
                }}
              />
              <div className="flex flex-row h-full w-full overflow-hidden">
                <MainLayout />
                <ChatPanel open={chatOpen} />
              </div>
              <ManagePeerModal
                open={peerModalStore.open}
                onClose={() => peerModalStore.setOpen(false)}
              />
            </div>
          </RoomEnter>
        </WaitForWsAndAuth>
      ) : undefined}
    </>
  );
};

RoomPage.ws = true;

RoomPage.getInitialProps = async ({ query }) => {
  let room = null;

  try {
    const resp: any = await (
      await fetch(`${apiBaseUrl}/room/${query.id}`)
    ).json();

    if ("room" in resp) {
      room = resp.room;
    }
  } catch {}

  return { room };
};

export default RoomPage;
