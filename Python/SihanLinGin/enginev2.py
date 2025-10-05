import streamlit as st
import yaml
from pyvis.network import Network

# --- Load YAML ---
with open("SihanProAdvanced.yaml", "r") as f:
    config = yaml.safe_load(f)
pipelines = config["pipelines"]

# --- Extract all nodes and gold tables ---
all_edges = []
for p in pipelines:
    all_edges.extend(p["edges"])

all_targets = [edge["to"] for edge in all_edges]
gold_tables = [t for t in all_targets if "gold" in t.lower() or "dbo" in t.lower()]

# --- Streamlit UI ---
st.title("🧷SihanLinGin")
selected_table = st.selectbox("Select a Gold Table to Explore:", sorted(set(gold_tables)))

# --- Helper to color by layer ---
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

# --- Build graph filtered by selected gold table ---
net = Network(directed=True, height="650px", width="100%", bgcolor="white", font_color="black")

# Find all edges that are connected (directly or indirectly) to selected_table
def find_related_edges(target):
    related = []
    current_targets = {target}
    while current_targets:
        new_targets = set()
        for e in all_edges:
            if e["to"] in current_targets:
                related.append(e)
                new_targets.add(e["from"])
        current_targets = new_targets
    return related

related_edges = find_related_edges(selected_table)

# Add nodes/edges to graph
for e in related_edges:
    src, tgt, trig = e["from"], e["to"], e.get("via")
    net.add_node(src, label=src, color=node_color(src))
    net.add_node(tgt, label=tgt, color=node_color(tgt))

    if trig:
        trig_node = f"{trig}"
        net.add_node(trig_node, Lable=trig, color="red", shape="box")
        net.add_edge(src, trig_node, title=f"Pipeline Step")
        net.add_edge(trig_node, tgt, title=f"Pipeline Step")
    else:
        net.add_edge(src, tgt, title=f"Pipeline Step")

# --- Show the graph ---
net.save_graph("filtered_lineage.html")
st.components.v1.html(open("filtered_lineage.html", "r").read(), height=650)
