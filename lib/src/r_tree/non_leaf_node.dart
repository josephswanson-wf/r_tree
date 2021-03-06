/*
 * Copyright 2015 Workiva Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

part of r_tree;

class NonLeafNode<E> extends Node<E> {
  List<Node<E>> _childNodes = [];
  List<Node<E>> get children => _childNodes;

  NonLeafNode(int branchFactor) : super(branchFactor);

  Node<E> createNewNode() {
    return new NonLeafNode<E>(branchFactor);
  }

  Iterable<RTreeDatum<E>> search(Rectangle searchRect) {
    List<RTreeDatum<E>> overlappingLeafs = [];

    _childNodes.forEach((Node<E> childNode) {
      if (childNode.overlaps(searchRect)) {
        overlappingLeafs.addAll(childNode.search(searchRect));
      }
    });

    return overlappingLeafs;
  }

  Node<E> insert(RTreeDatum<E> item) {
    include(item);

    Node<E> bestNode = _getBestNodeForInsert(item);
    Node<E> splitNode = bestNode.insert(item);

    if (splitNode != null) {
      addChild(splitNode);
    }

    return splitIfNecessary();
  }

  remove(RTreeDatum<E> item) {
    List<Node<E>> childrenToRemove = [];

    _childNodes.forEach((Node<E> childNode) {
      if (childNode.overlaps(item.rect)) {
        childNode.remove(item);

        if (childNode.size == 0) {
          childrenToRemove.add(childNode);
        }
      }
    });

    childrenToRemove.forEach((Node<E> child) {
      removeChild(child);
    });
  }

  addChild(Node<E> child) {
    super.addChild(child);
    child.parent = this;
  }

  removeChild(Node<E> child) {
    super.removeChild(child);
    child.parent = null;

    if (_childNodes.length == 0) {
      _convertToLeafNode();
    }
  }

  clearChildren() {
    _childNodes = [];
    _minimumBoundingRect = null;
  }

  Node<E> _getBestNodeForInsert(RTreeDatum<E> item) {
    num bestCost = double.INFINITY;
    num tentativeCost;
    Node<E> bestNode;

    _childNodes.forEach((Node<E> child) {
      tentativeCost = child.expansionCost(item);
      if (tentativeCost < bestCost) {
        bestCost = tentativeCost;
        bestNode = child;
      }
    });

    return bestNode;
  }

  _convertToLeafNode() {
    var nonLeafParent = parent as NonLeafNode<E>;
    if (nonLeafParent == null) return;

    var newLeafNode = new LeafNode<E>(this.branchFactor);
    newLeafNode.include(this);
    nonLeafParent.removeChild(this);
    nonLeafParent.addChild(newLeafNode);
  }
}
