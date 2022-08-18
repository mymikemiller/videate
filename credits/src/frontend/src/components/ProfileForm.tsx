import {
  ActionButton,
  Form,
  Heading,
  TextField,
} from "@adobe/react-spectrum";
import { ActorSubclass } from "@dfinity/agent";
import React from "react";
import {
  Bio,
  ProfileUpdate,
  _SERVICE,
} from "../../../declarations/serve/serve.did";
import { emptyProfile } from "../hooks";

interface Props {
  profile: ProfileUpdate;
  submitCallback: (profile: ProfileUpdate) => void;
  actor?: ActorSubclass<_SERVICE>;
}

class ProfileForm extends React.Component<Props> {
  state = { profile: emptyProfile };

  formRef = React.createRef();

  constructor(props: Props) {
    super(props);
  }

  componentDidMount() {
    if (this.props.profile) {
      this.setState({ profile: this.props.profile });
    }
  }

  handleChange(key: string, value: string) {
    const newState: any = { profile: this.state.profile };
    newState.profile.bio[key] = value ? [value] : [];
    this.setState(newState);
  }

  handleSubmit() {
    const { name } = this.state.profile.bio;
    const newProfile = Object.assign({}, this.state.profile);
    newProfile.bio.name = name;

    this.props.submitCallback(newProfile);
  }

  render() {
    const { name } =
      this.state.profile.bio;

    const handleChange = this.handleChange.bind(this);
    const handleSubmit = this.handleSubmit.bind(this);
    return (
      <section>
        <Heading level={1}>Create a Profile</Heading>
        <Form
          onSubmit={(e) => {
            e.preventDefault();
            handleSubmit();
          }}
        >
          <TextField
            label="Name"
            name="name"
            value={name[0] || ""}
            onChange={(value) => handleChange("name", value)}
          />
          <ActionButton type="submit">Submit</ActionButton>
        </Form>
      </section>
    );
  }
}

export default ProfileForm;
