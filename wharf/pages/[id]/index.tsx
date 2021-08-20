import React from "react";
import { PageComponent } from "@port7/types/page-component";
import { apiBaseUrl } from "@port7/lib/constants";
import { WaitForWsAndAuth } from "@port7/modules/auth/wait-for-ws-auth";
import { useConn } from "@port7/hooks/use-conn";
import { Room } from "@port7/dock";
import { WaitForSetUser } from "@port7/modules/room/wait-for-set-user";
import { RoomEnter } from "@port7/modules/room/room-enter";
import { useRoomStore } from "@port7/modules/room/use-room-store";
import { Header } from "@port7/modules/room/header";
import { MainLayout } from "@port7/modules/room/main-layout";
import { Chat } from "@port7/modules/room/chat";

interface RoomPageProps {
  room?: Room;
}

const RoomPage: PageComponent<RoomPageProps> = ({ room }) => {
  const conn = useConn();
  const roomStore = useRoomStore();

  React.useEffect(() => {
    roomStore.setRoom(room);
  }, [room]);

  return (
    <>
      {room ? (
        <WaitForWsAndAuth>
          <WaitForSetUser room={room}>
            {room ? (
              <RoomEnter room={room}>
                <div className="w-full h-full flex flex-col">
                  <Header />
                  <div className="flex flex-row h-full w-full overflow-hidden">
                    <MainLayout />
                    <Chat />
                  </div>
                </div>
              </RoomEnter>
            ) : undefined}
          </WaitForSetUser>
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

    console.log(resp);
    if ("room" in resp) {
      room = resp.room;
    }
  } catch {}

  return { room };
};

export default RoomPage;
