'use strict';

angular.module('mvsouza.angular-rrssb', []).directive('rrssb', function () {
  var mediasAvailable = ['facebook','pinterest','pocket','github','googleplus','reddit','twitter','linkedin','email'];
  return {
    restrict: 'AE',
    templateUrl: 'angular-rrssb.html',
    replcae: true,
    link: function ($scope, element, attr) {
      $scope.$watch('$viewContentLoaded', rrssbInit);
      $scope.urlToShare = attr.ngShareLink;
      $scope.shareMidias = attr.ngShareMidias;
      $scope.showAll = false || attr.ngShareAll; 
      $scope.shoulShow = function (socialNetworkName) {
        return ($scope.shareMidias && $scope.shareMidias.indexOf(socialNetworkName)>-1) || $scope.showAll;
      };
      $scope.pinterestImg = attr.ngPinterestImg;
      if(attr.ngGithubProject)$scope.githubProject = attr.ngGithubProject;
      $scope.title = attr.ngShareTitle || ""; 
      $scope.encode = function (text) {
        return encodeURIComponent(text);
      };
    }
  };
});