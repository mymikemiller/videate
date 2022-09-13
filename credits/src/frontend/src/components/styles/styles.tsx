
import styled from "styled-components";

export const Section = styled.section`
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
`;

export const FormContainer = styled.div`
  background-color: #262626;
  width: 90%;
  // margin: 50px auto;

  padding: 20px;
  display: block;
`;
export const Title = styled.h3`
  padding: 0 0 20px 0;
`;

export const Label = styled.label`
  width:100%;
`;
export const Input = styled.input`
  width: 100%;
  background-color: #676767;
  padding: 10px;
  border-radius: 4px;
  color: white;
  margin: 8px 0;
  border: none;
  box-sizing: border-box;
`;
export const GrowableInput = styled.textarea`
  width: 100%;
  background-color: #676767;
  padding: 20px;
  border-radius: 4px;
  color: white;
  margin: 8px 0;
  border: none;
  box-sizing: border-box;
`;
export const Select = Input;

export const LargeButton = styled(Input)`
  background-color: transparent;
  color: white;
  font-size: 20px;
  cursor: pointer;
`;
export const LargeBorder = styled.div`
  background: #262626;
  cursor: pointer;
  border-radius: 5px;
`;
export const LargeBorderWrap = styled.div`
  width: 100%;
  margin: 0 auto;
  background: linear-gradient(to right, #147369, #14732B, #0DF205);
  padding: 2px;
  cursor: pointer;
  border-radius: 5px;
`;

export const ValidationError = styled.div`
  color: #D00000;
  padding: 0px 0px 10px 0px;
`;
