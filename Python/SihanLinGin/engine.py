import streamlit as st
import yaml
from pyvis.network import Network

# Load YAML
with open("lineage.yaml", "r") as f:
    config = yaml.safe_load(f)

pipelines = config["pipelines"]

# Initialize network
net = Network(directed=True, height="700px", width="100%", bgcolor="white", font_color="black")

# Helper function for node colors
def node_color(name):
    if name.lower().startswith("blob"):
        return "lightblue"
    elif "staging" in name.lower():
        return "orange"
    elif "ods" in name.lower():
        return "lightgreen"
    elif "gold" in name.lower():
        return "gold"
    elif "vw" in name.lower() or "dbo" in name.lower():
        return "violet"
    else:
        return "gray"

# Add all pipelines
for pipeline in pipelines:
    for edge in pipeline["edges"]:
        src = edge["from"]
        tgt = edge["to"]
        trigger = edge["via"]

        # Add dataset nodes
        net.add_node(src, label=src, color=node_color(src))
        net.add_node(tgt, label=tgt, color=node_color(tgt))

        # Add trigger as separate node (optional)
        trigger_node = f"{pipeline['name']}::{trigger}"  # unique name
        net.add_node(trigger_node, label=trigger, color="red", shape="box")

        # Connect src -> trigger -> tgt
        net.add_edge(src, trigger_node, title=f"Pipeline: {pipeline['name']}")
        net.add_edge(trigger_node, tgt, title=f"Pipeline: {pipeline['name']}")

# Save and display
net.save_graph("lineage.html")
st.components.v1.html(open("lineage.html", "r").read(), height=700)
