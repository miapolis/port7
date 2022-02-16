export interface Transform {
  originX: number;
  originY: number;
  translateX: number;
  translateY: number;
  scale: number;
}

export class State {
  public minScale: number;
  public maxScale: number;
  public scaleSensitivity: number;
  public transform: Transform;
  public elementTransform: string;
  public elementTransformOrigin: string;

  public constructor(
    minScale: number,
    maxScale: number,
    scaleSensitivity: number
  ) {
    this.minScale = minScale;
    this.maxScale = maxScale;
    this.scaleSensitivity = scaleSensitivity;
    this.elementTransform = "";
    this.elementTransformOrigin = "";
    this.transform = {
      originX: 0,
      originY: 0,
      translateX: 0,
      translateY: 0,
      scale: 1,
    };
  }

  public panTo = (originX: number, originY: number, scale: number) => {
    this.transform.scale = scale;
    return this.pan(
      originX - this.transform.translateX,
      originY - this.transform.translateY
    );
  };

  public pan = (originX: number, originY: number) => {
    this.transform.translateY += originY;
    this.transform.translateX += originX;

    this.elementTransform = getMatrix(
      this.transform.scale,
      this.transform.translateX,
      this.transform.translateY
    );

    return this.elementTransform;
  };

  public zoom = (
    x: number,
    y: number,
    deltaScale: number,
    boundingLeft: number,
    boundingTop: number
  ) => {
    let { minScale, maxScale, scaleSensitivity } = this;
    const [scale, newScale] = getScale(
      this.transform.scale,
      minScale,
      maxScale,
      scaleSensitivity,
      deltaScale
    );

    const originX = x - boundingLeft;
    const originY = y - boundingTop;
    const newOriginX = originX / scale;
    const newOriginY = originY / scale;

    const translate = getTranslate(scale, minScale, maxScale);
    const translateX = translate(
      originX,
      this.transform.originX,
      this.transform.translateX
    );
    const translateY = translate(
      originY,
      this.transform.originY,
      this.transform.translateY
    );

    this.elementTransform = getMatrix(newScale, translateX, translateY);
    this.elementTransformOrigin = `${newOriginX}px ${newOriginY}px`;
    this.transform = {
      originX: newOriginX,
      originY: newOriginY,
      translateX,
      translateY,
      scale: newScale,
    };

    return [
      this.elementTransform,
      this.elementTransformOrigin,
      this.transform.scale,
    ];
  };
}

const getTranslate =
  (scale: number, minScale: number, maxScale: number) =>
  (pos: number, prevPos: number, translate: number) =>
    inRange(scale, minScale, maxScale) && pos !== prevPos
      ? translate + (pos - prevPos * scale) * (1 - 1 / scale)
      : translate;

const getScale = (
  scale: number,
  minScale: number,
  maxScale: number,
  scaleSensitivity: number,
  deltaScale: number
) => {
  let newScale = scale + deltaScale / (scaleSensitivity / scale);
  newScale = Math.max(minScale, Math.min(newScale, maxScale));
  return [scale, newScale];
};

const getMatrix = (scale: number, translateX: number, translateY: number) =>
  `matrix(${scale}, 0, 0, ${scale}, ${translateX}, ${translateY})`;

const inRange = (scale: number, minScale: number, maxScale: number) =>
  scale <= maxScale && scale >= minScale;
