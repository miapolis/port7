import { me } from "@port7/modules/room/use-room-store";

// Perhaps consider moving this to dock
type Intent = "MANAGE PEERS" | "PROMOTE PEERS"; // TODO: Add more

export const myIntents = (): Intent[] => {
  let self = me();
  const roles = self.roles;
  let intents = new Array<Intent>();

  roles.forEach((role) => {
    switch (role.toLowerCase()) {
      case "leader":
        intents = intents.concat(["MANAGE PEERS", "PROMOTE PEERS"]);
        break;
    }
  });

  return intents;
};
