import * as React from "react";
import styled from "styled-components";
import glitch from "../../assets/glitch-loop.webp";

interface Props {
  message?: string;
}

const Figure = styled.figure`
  margin: 0;
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.75);
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  img {
    margin: 2rem auto;
    max-width: calc(100vw - 2rem);
  }
`;

function Loading(props: Props) {
  const { message = "Loading..." } = props;

  return (
    <>
      <Figure>
        <img src={glitch} alt="Page is loading" />
        <figcaption>
          <h3>{message}</h3>
        </figcaption>
      </Figure>
    </>
  );
}

export default Loading;
