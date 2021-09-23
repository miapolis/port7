export class Queue<T> {
  elements: T[] = [];

  push(elem: T) {
    this.elements.push(elem);
  }

  pop(): T | undefined {
    return this.elements.shift();
  }
}
