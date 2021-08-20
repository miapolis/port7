export type RoomCreateResponse = {
  data: Room | null,
  errors: string[] | undefined,
}

export type Room = {
  id: string,
  name: string,
  code: string,
  isPrivate: string,
}
